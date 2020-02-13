terraform {
  backend "gcs" {
    bucket = "mulatocloud-tfstate"
    prefix = "dev-cluster"
  }
}
data "terraform_remote_state" "network" {
  backend = "gcs"

  config = {
    bucket = "mulatocloud-tfstate"
    prefix = "dev-network"
  }
}

provider "google" {
  credentials = file("/home/mlt/cloud/accounts/mulatocloud-79bf0469e1be.json")
  project     = var.project 
  region      = var.region
}

resource "google_container_cluster" "app-cluster" {
  name                     = var.name
  network                  = var.vpc 
  subnetwork               = var.subnet 
  remove_default_node_pool = true
  initial_node_count       = 1
  location                 = var.region_list[0]

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods" 
    services_secondary_range_name = "services" 
  }

  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = false
    master_ipv4_cidr_block = var.cidr_master 
  }

  lifecycle {
    ignore_changes = [ node_config, initial_node_count, ]
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      minimum       = "450"
      maximum       = "750"
    }
    resource_limits {
      resource_type = "memory"
      minimum       = "1"
      maximum       = "3"
    }
    auto_provisioning_defaults {
      oauth_scopes = [
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
        "https://www.googleapis.com/auth/compute",
      ]
    }
  }
}

resource "google_container_node_pool" "node-pool" {
  name       = var.first_pool
  cluster    = google_container_cluster.app-cluster.name
  location   = var.region_list[0]
  node_count = 2

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  autoscaling {
    min_node_count = 2
    max_node_count = 4
  }

  node_config {
    preemptible  = "true"
    disk_size_gb = "30"
    disk_type    = "pd-ssd"
    machine_type = "n1-standard-1"
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/compute",
    ]
  }
}
