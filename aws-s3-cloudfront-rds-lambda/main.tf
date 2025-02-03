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

# AWS VPC with Subnets
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "Default"
    Service = "VPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public"
    Service = "Subnet"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Private A "
    Service = "Subnet"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Private B"
    Service = "Subnet"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "Subnet Group"
    Service = "Subnet"
  }
}

# Secrets Manager for RDS Credentials
resource "random_password" "rds_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name = "rds-credentials"
}

resource "aws_secretsmanager_secret" "monitoring_secret" {
  name = "monitoring-credentials"
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = var.db_username,
    password = random_password.rds_password.result,
    host     = aws_db_instance.postgres.address,
    dbname   = "tasksdb"
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

#data "aws_secretsmanager_secret_version" "rds_secret_version" {
#  secret_id = aws_secretsmanager_secret.rds_secret.id
#}

data "aws_secretsmanager_secret_version" "monitoring_secret_version" {
  secret_id = aws_secretsmanager_secret.monitoring_secret.id
}


# RDS Instance
resource "aws_db_instance" "postgres" {
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

# RDS Firewall.
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Apenas VPC interna pode acessar
  }
}
