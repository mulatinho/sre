variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "db_username" {
  description = "Username for RDS"
  default     = "tasks_owner"
}

variable "db_name" {
  description = "Username for RDS"
  default     = "tasks"
}
