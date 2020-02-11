variable "name" {
  default = "dev"
}

variable "vpc" {
  default = "dev-vpc"
}

variable "subnet" {
  default = "dev-subnet"
}

variable "project" {
  default = "mulatocloud"
}

variable "region" {
  default = "us-east1"
}

variable "region_list" {
  type = list
  default = [ "us-east1-b", "us-east1-c", "us-east1-d" ]
}

variable "cidr_master" {
  default = "10.0.0.0/28"
}

variable "cidr_be_list" {
  type = list
  default = [ "10.1.0.0/16", "10.10.0.0/16", "10.11.0.0/16" ]
}

variable "first_pool" {
  default = "dev-pool" 
}

