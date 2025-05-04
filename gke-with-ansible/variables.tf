locals {
  project_id              = "mulatocloud"
  region                  = "us-central1"
  vpc_name                = "mulatovpc"
  default_subnetwork_name = "mulatosubnet"
  default_cidr_range      = "10.0.0.0/16"
  k8s_subnetwork_name     = "k8subnet"
  k8s_cidr_range          = "10.1.0.0/16"
  router_name             = "mulatorouter"
  router_nat_name         = "mulatonat"
  pods_range_name         = "k8spods"
  pods_cidr_range         = "10.200.0.0/22"
  svc_range_name          = "k8ssvcs"
  svc_cidr_range          = "10.220.0.0/20"
  k8s_sa_name             = "k8s-sa"
  k8s_sa_display_name     = "Kubernetes Service Account"
  cluster_name            = "mulatok8s"
  location                = "us-central1-a"
  initial_node_count      = 1
  vms_sa_name             = "vms-sa"
  vms_sa_display_name     = "VMs Service Account"
  ssh_username            = "mlt"
  ssh_pub_key_path        = "/home/mlt/.ssh/id_rsa.pub"
}

variable "machine" {
  type = object({
    name       = string
    location   = string
    type       = string
    size       = number
    node_count = number
  })
  default = {
    name       = "mlt"
    location   = "us-central1-a"
    type       = "n1-standard-2"
    size       = 100
    node_count = 2
  }
}
