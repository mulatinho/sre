variable "project_name" {
  type    = string
  default = "vpc"
}

variable "project_region" {
  type    = string
  default = "us-central1"
}

variable "project_orgid" {
  type    = string
  default = ""
}

variable "project_billing_account_id" {
  type    = string
  default = "vpc"
}

variable "services_enable" {
  type = list(string)
  default = [
    "cloudbilling.googleapis.com",
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ]
}
