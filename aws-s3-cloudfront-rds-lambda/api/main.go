package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
	_ "github.com/lib/pq"
)

var (
	db              *sql.DB
	monitoringCreds *MonitoringCredentials
)

type Task struct {
	ID          int    `json:"id"`
	Description string `json:"description"`
	CreatedAt   string `json:"created_at"`
}

type RDSCredentials struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Host     string `json:"host"`
	Port     int    `json:"port"`
	DBName   string `json:"dbname"`
}

type MonitoringCredentials struct {
	SentryDSN   string `json:"sentry_dsn"`
	SplunkURL   string `json:'splunk_url"`
	SplunkToken string `json:"splunk_token"`
}

func logToSplunk(event string) {

	bodyString := []byte(`{ "event": "` + event + `" }`)
	bodyParsed := bytes.NewBuffer(bodyString)

	req, _ := http.NewRequest("POST", monitoringCreds.SplunkURL, bodyParsed)
	req.Header.Set("Authorization", "Splunk "+monitoringCreds.SplunkToken)
	req.Header.Set("Content-Type", "application/json")

	_, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Fatalf("splunkError: %v", err)
	}
}

func getRDSCredentials() (*RDSCredentials, error) {
	secretName := "db-credentials"
	svc := secretsmanager.New(session.Must(session.NewSession()), aws.NewConfig().WithRegion("us-east-1"))

	input := &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretName),
	}

	result, err := svc.GetSecretValue(input)
	if err != nil {
		return nil, fmt.Errorf("failed to get secret: %v", err)
	}

	var creds RDSCredentials
	err = json.Unmarshal([]byte(*result.SecretString), &creds)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal secret: %v", err)
	}

	return &creds, nil
}

func getMonitoringCredentials() (*MonitoringCredentials, error) {
	secretName := "monitor-credentials"
	svc := secretsmanager.New(session.Must(session.NewSession()), aws.NewConfig().WithRegion("us-east-1"))

	input := &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretName),
	}

	result, err := svc.GetSecretValue(input)
	if err != nil {
		return nil, fmt.Errorf("failed to get secret: %v", err)
	}

	var creds MonitoringCredentials
	err = json.Unmarshal([]byte(*result.SecretString), &creds)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal secret: %v", err)
	}

	return &creds, nil
}

// Handles API requests
func handler(req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	switch req.HTTPMethod {
	case "POST":
		fmt.Println("You are doing a POST")
		var task Task
		if err := json.Unmarshal([]byte(req.Body), &task); err != nil {
			logToSplunk("Error: " + err.Error())
			return events.APIGatewayProxyResponse{StatusCode: 400, Body: `{"error": "Invalid JSON"}`}, nil
		}

		err := db.QueryRow("INSERT INTO tasks (description) VALUES ($1) RETURNING id", task.Description).Scan(&task.ID)
		if err != nil {
			return events.APIGatewayProxyResponse{StatusCode: 500, Body: fmt.Sprintf(`{"error": "%v"}`, err)}, nil
		}

		taskJSON, _ := json.Marshal(task)
		return events.APIGatewayProxyResponse{StatusCode: 201, Body: string(taskJSON)}, nil
	case "GET":
		fmt.Println("You are doing a GET")
		rows, err := db.Query("SELECT id, description, created_at FROM tasks")
		if err != nil {
			logToSplunk("Error: " + err.Error())
			return events.APIGatewayProxyResponse{StatusCode: 500, Body: `{"error": "Failed to fetch tasks"}`}, nil
		}
		defer rows.Close()

		var tasks []Task
		for rows.Next() {
			var t Task
			if err := rows.Scan(&t.ID, &t.Description, &t.CreatedAt); err != nil {
				logToSplunk("Error: " + err.Error())
				return events.APIGatewayProxyResponse{StatusCode: 500, Body: `{"error": "Failed to parse tasks"}`}, nil
			}
			tasks = append(tasks, t)
		}

		responseBody, _ := json.Marshal(tasks)
		return events.APIGatewayProxyResponse{StatusCode: 200, Body: string(responseBody)}, nil
	default:
		err := fmt.Errorf("unsupported method: %s", req.HTTPMethod)
		logToSplunk("Error: " + err.Error())
		return events.APIGatewayProxyResponse{StatusCode: 405}, nil
	}
}

func main() {
	creds, err := getRDSCredentials()
	if err != nil {
		log.Fatalf("Could not retrieve RDS credentials: %v", err)
	}
	monitoringCreds, err = getMonitoringCredentials()
	if err != nil {
		log.Fatalf("Could not retrieve RDS credentials: %v", err)
	}

	connStr := fmt.Sprintf(
		"host=%s dbname=%s user=%s password=%s port=5432",
		creds.Host, creds.DBName, creds.Username, creds.Password,
	)

	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	fmt.Printf("Connected to DB: %s\ndb: %#v\n", creds.DBName, db)
	fmt.Printf("creds: %#v\nmonitoringCreds: %#v\n", creds, monitoringCreds)

	_, err = db.Query("CREATE TABLE IF NOT EXISTS tasks (id SERIAL PRIMARY KEY, description TEXT NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);")
	if err != nil {
		fmt.Println(err)
		logToSplunk("Error: " + err.Error())
	}

	fmt.Println("Starting Lambda")
	lambda.Start(handler)
}
