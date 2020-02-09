terraform {
  backend "gcs" {
    bucket = "mulatocloud-tfstate"
    prefix = "dev"
  }
}

provider "google" {
  credentials = file("/home/mlt/cloud/accounts/mulatocloud-79bf0469e1be.json")
  project     = var.project 
  region      = var.region
}

data "google_compute_address" "ip-address" {
  name = "${var.name}-public"
}

resource "google_compute_network" "app-vpc" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "app-subnet-be" {
  name          = "${var.name}-subnet"
  ip_cidr_range = var.cidr_be_list[0]
  secondary_ip_range = [
    { 
      range_name = "pods" 
      ip_cidr_range = var.cidr_be_list[1] 
    },
    {
      range_name = "services" 
      ip_cidr_range = var.cidr_be_list[2]
    }
  ]
  network	           = google_compute_network.app-vpc.name
  private_ip_google_access = true
}

resource "google_compute_firewall" "app-fw" {
  name    = "app-fw"
  network = google_compute_network.app-vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = [ "22", "80", "443" ]
  }

  source_ranges = [ "0.0.0.0/0" ]
}

resource "google_container_cluster" "app-cluster" {
  name                     = var.name
  network                  = google_compute_network.app-vpc.name
  subnetwork               = google_compute_subnetwork.app-subnet-be.name 
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
    ignore_changes = [ node_config, ]
  }
}

resource "google_container_node_pool" "nodes-be" {
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

resource "google_compute_router" "router" {
  name    = "${var.name}-router"
  network = google_compute_network.app-vpc.name
  region  = var.region
  bgp {
    asn               = 64514
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}

resource "google_compute_router_nat" "nat_router" {
  name                               = "${var.name}-nat"
  router                             = google_compute_router.router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
