const AWS = require("aws-sdk");
const { Client } = require("pg");
const axios = require("axios");
const Sentry = require("@sentry/aws-serverless");

// Load AWS Secrets Manager
const secretsManager = new AWS.SecretsManager();

async function getSecrets() {
    let secrets = {};
    const SECRET_NAMES = ["db-credentials", "monitoring-credentials"];
    for (let secretName of SECRET_NAMES) {
        const secret = await secretsManager.getSecretValue({ SecretId: secretName }).promise();
        secrets[secretName] = JSON.parse(secret.SecretString);
    }
    return secrets;
}

exports.handler = async (event) => {
    let client;
    
    const secrets = await getSecrets();
    const rdsCreds = secrets["db-credentials"];
    const monitoringCreds = secrets["monitoring-credentials"];

    const sentryDsn = monitoringCreds.sentry_dsn;
    const splunkUrl = monitoringCreds.splunk_url;
    const splunkToken = monitoringCreds.splunk_token;

    try {
        Sentry.init({ dsn: sentryDsn });

        client = new Client({
            host: rdsCreds.host,
            port: 5432,
            user: rdsCreds.username,
            password: rdsCreds.password,
            database: rdsCreds.dbname,
            ssl: { rejectUnauthorized: false }
        });

        await client.connect();
        await client.query("CREATE TABLE IF NOT EXISTS tasks ( id SERIAL PRIMARY KEY, description TEXT NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP");
        console.log("INIT")

        if (event.httpMethod === "POST") {
            const { description } = JSON.parse(event.body);
            const result = await client.query("INSERT INTO tasks (description) VALUES ($1) RETURNING id;", [description]);
            
            await logToSplunk(splunkUrl, splunkToken, {
              action: "TaskCreated", 
              task_id: result.rows[0].id 
            });

            console.log("Task Created", result)
            return {
                statusCode: 201,
                body: JSON.stringify({ task_id: result.rows[0].id }),
            };

        } else if (event.httpMethod === "GET") {
            const result = await client.query("SELECT id, description, created_at FROM tasks;");
            console.log("TasksList", result)

            await logToSplunk(splunkUrl, splunkToken, {
              action: "TasksList", 
              task_id: result.rows[0].id 
            });

            return {
                statusCode: 200,
                body: JSON.stringify(result.rows),
            };
        } else {
            Sentry.captureException(error)
            return { statusCode: 405, body: JSON.stringify({ error: "Method Not Allowed" }) };
        }
    } catch (error) {
        console.error("Error:", error);
        Sentry.captureException(error)
        await logToSplunk(splunkUrl, splunkToken, { error: error.message });

        return { statusCode: 500, body: JSON.stringify({ error: "Internal Server Error" }) };
    } finally {
        if (client) await client.end();
    }
};

// Function to log events to Splunk
async function logToSplunk(url, token, event) {
    try {
        await axios.post(url, { event }, {
            headers: { Authorization: `Splunk ${token}`, "Content-Type": "application/json" }
        });
    } catch (err) {
        console.error("Failed to send log to Splunk:", err.message);
    }
}

