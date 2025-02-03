variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "db_username" {
  description = "Username for RDS"
  default     = "tasks_owner"
}

variable "db_name" {
  description = "Database Name"
  default     = "tasksdb"
}

variable "sentry_dsn" {
  description = "Sentry TOKEN"
}

variable "splunk_url" {
  description = "Splunk URL"
}

variable "splunk_token" {
  description = "Splunk TOKEN"
}
