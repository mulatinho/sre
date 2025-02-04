terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "mulatocloud-tf"
    key    = "sre-challenge-lab01-tfstate"
    region = "us-east-1"
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "lambda-keypair" {
  key_name   = "lambda-keypair"
  public_key = file("~/.ssh/id_rsa.pub")
}

##
## AWS VPC with Subnets
##

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name    = "main"
    Service = "VPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name    = "public"
    Service = "Subnet"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name    = "private_a"
    Service = "Subnet"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name    = "private_b"
    Service = "Subnet"
  }
}

resource "aws_internet_gateway" "lambda-igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "lambda-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lambda-igw.id
  }

  tags = {
    name = "lambda-rt"
  }
}

resource "aws_route_table_association" "rt_public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.lambda-rt.id
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name    = "subnet_group"
    Service = "Subnet"
  }
}

##
## Secrets Manager for RDS Credentials
##

resource "random_password" "rds_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name                    = "db-credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret" "monitoring_secret" {
  name                    = "monitor-credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = var.db_username,
    password = random_password.rds_password.result,
    host     = aws_db_instance.postgres.address,
    dbname   = var.db_name
  })
}

resource "aws_secretsmanager_secret_version" "monitoring_secret_version" {
  secret_id = aws_secretsmanager_secret.monitoring_secret.id
  secret_string = jsonencode({
    sentry_dsn   = var.sentry_dsn,
    splunk_url   = var.splunk_url,
    splunk_token = var.splunk_token,
  })
}

##
## RDS Instance
##

resource "aws_db_instance" "postgres" {
  tags = {
    Name    = var.db_name
    Service = "RDS"
  }
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.rds_password.result
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
}

##
## Security Group - Firewalls
##

resource "aws_security_group" "db_sg" {
  name   = "db_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lambda_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.db_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##
## IAM Roles and Policies
##

resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
  tags = {
    Name    = "Lambda Role"
    Service = "IAM"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "lambda_secrets_policy" {
  name        = "LambdaSecretsAccess"
  description = "Allow Lambda to get RDS credentials from Secrets Manager"
  tags = {
    Name    = "Lambda Secret Policy"
    Service = "IAM"
  }

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = [aws_secretsmanager_secret.rds_secret.arn, aws_secretsmanager_secret.monitoring_secret.arn]
    }]
  })
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "LambdaLoggingPolicy"
  description = "Allows Lambda to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

resource "aws_iam_policy" "lambda_vpc_permissions" {
  name        = "LambdaVPCPermissions"
  description = "Allow Lambda to create network interfaces in VPC"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_permissions_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_vpc_permissions.arn
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_secrets_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logging_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

##
## API Gateway /tasks
##

resource "aws_api_gateway_rest_api" "tasks_api" {
  name        = "tasks_api"
  description = "Tasks API"
  tags = {
    Name    = "Lambda API Tasks"
    Service = "Gateway API"
  }
}

resource "aws_api_gateway_resource" "tasks" {
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
  parent_id   = aws_api_gateway_rest_api.tasks_api.root_resource_id
  path_part   = "tasks"
}

# resource "aws_api_gateway_method" "post_task" {
#   rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
#   resource_id   = aws_api_gateway_resource.tasks.id
#   http_method   = "POST"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_method" "get_tasks" {
#   rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
#   resource_id   = aws_api_gateway_resource.tasks.id
#   http_method   = "GET"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "lambda_post_task" {
#   rest_api_id             = aws_api_gateway_rest_api.tasks_api.id
#   resource_id             = aws_api_gateway_resource.tasks.id
#   http_method             = aws_api_gateway_method.post_task.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.tasks_lambda.invoke_arn
# }

# resource "aws_api_gateway_integration" "lambda_get_tasks" {
#   rest_api_id             = aws_api_gateway_rest_api.tasks_api.id
#   resource_id             = aws_api_gateway_resource.tasks.id
#   http_method             = aws_api_gateway_method.get_tasks.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.tasks_lambda.invoke_arn
# }

resource "aws_api_gateway_deployment" "deployment" {
#  depends_on  = [aws_api_gateway_integration.lambda_post_task, aws_api_gateway_integration.lambda_get_tasks]
  rest_api_id = aws_api_gateway_rest_api.tasks_api.id
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.tasks_api.id
  stage_name    = "dev"
}

output "aws_api_gatewat_stage" {
  value = aws_api_gateway_stage.dev.invoke_url
}
##
## APP Lambda in Node.js
##

resource "aws_lambda_function" "tasks_lambda" {
  depends_on    = [aws_iam_policy.lambda_logging, aws_iam_policy.lambda_secrets_policy, aws_iam_policy.lambda_vpc_permissions]
  function_name = "tasks_handler"
  role          = aws_iam_role.lambda_role.arn
#  handler       = "main"
  image_uri     = "709142056059.dkr.ecr.us-east-1.amazonaws.com/mulatocloud/images:latest"
  package_type  = "Image"
  timeout       = 5

   #vpc_config {
   #  subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
   #  security_group_ids = [aws_security_group.lambda_sg.id]
   #}

  tags = {
    Name    = "Tasks Lambda"
    Service = "Lambda"
  }
}

#resource "aws_lambda_function_url" "tasks_lambda_url" {
#  depends_on         = [aws_lambda_function.tasks_lambda]
#  function_name      = aws_lambda_function.tasks_lambda.function_name
#  authorization_type = "NONE"
#
#  cors {
#    allow_origins = ["*"]
#    allow_methods = ["HEAD", "GET", "POST"]
#    allow_headers = ["content-type"]
#  }
#}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tasks_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.tasks_api.execution_arn}/*/*"
}

#output "lambda_public_url" {
#  value = aws_lambda_function_url.tasks_lambda_url.function_url
#}

##
## AWS CloudWatch Monitoring 
##

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.tasks_lambda.function_name}"
  retention_in_days = 7
}

#resource "aws_cloudwatch_dashboard" "lambda_dashboard" {
#  dashboard_name = "lambda-monitoring"
#
#  dashboard_body = jsonencode({
#    widgets = [
#      {
#        type = "metric",
#        properties = {
#          title = "Lambda Invocations"
#          metrics = [
#            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.tasks_lambda.function_name]
#          ]
#          period = 60
#          stat   = "Sum"
#        }
#      },
#      {
#        type = "metric",
#        properties = {
#          title = "Lambda Errors"
#          metrics = [
#            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.tasks_lambda.function_name]
#          ]
#          period = 60
#          stat   = "Sum"
#        }
#      }
#    ]
#  })
#}

resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "lambda-error-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Triggers if Lambda errors exceed 1 per minute"
  alarm_actions       = [aws_sns_topic.lambda_alerts.arn]
  dimensions = {
    FunctionName = aws_lambda_function.tasks_lambda.function_name
  }
}


##
## AWS SNS 
##

resource "aws_sns_topic" "lambda_alerts" {
  name = "LambdaErrorAlerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.lambda_alerts.arn
  protocol  = "email"
  endpoint  = "alex.mulatinho@yahoo.com"
}

## test


resource "aws_security_group" "ec2_sg" {
  name   = "ec2_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "lambda_test_instance" {
  ami           = "ami-0e8087266e36fe754"
  instance_type = "t2.micro"
  key_name      = "lambda-keypair"
  subnet_id     = aws_subnet.public.id

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  provisioner "local-exec" {
    command = "sudo apt update -y && sudo apt install postgresql-client -y"
  }

  ebs_block_device {
    device_name           = "/dev/xvda"
    volume_size           = 8
    volume_type           = "gp2"
    delete_on_termination = true
  }
  tags = {
    Name = "lambda-test-instance"
  }
}

output "lambda_test_instance" {
  value = aws_instance.lambda_test_instance.public_ip
}
output "lambda_rds_instance" {
  value = aws_db_instance.postgres.address
}