terraform {
  backend "gcs" {
    bucket = "mulatocloud-tfstate"
    prefix = "dev-network"
  }
}

provider "google" {
  credentials = file("/home/mlt/cloud/accounts/mulatocloud-79bf0469e1be.json")
  project     = var.project 
  region      = var.region
}

resource "google_compute_address" "ip-address" {
  name = "${var.name}-public"
}

resource "google_compute_network" "app-vpc" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "app-subnet" {
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
  name    = "${var.name}-fw"
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
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips			     = google_compute_address.ip-address.*.self_link
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
