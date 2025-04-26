variable "project_name" {
  type    = string
  default = "vpc"
}

variable "project_environment" {
  type    = string
  default = "dev"
}

variable "project_region" {
  type    = string
  default = "us-central1"
}

variable "project_subnets" {
  type = any
  default = [
    { name = "defaul", cidr = "10.1.0.0/24" }
  ]
}