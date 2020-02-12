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

resource "google_compute_address" "ip-address" {
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

resource "google_compute_instance_template" "template_instance" {
    can_ip_forward       = true
    machine_type         = "n1-standard-1"
    name_prefix          = "vm"
    project              = var.project 
    region               = var.region

    disk {
        auto_delete  = true
        boot         = true
        device_name  = "persistent-disk-0"
        disk_size_gb = 30
        disk_type    = "pd-ssd"
        mode         = "READ_WRITE"
        type         = "PERSISTENT"
	source_image = "debian-cloud/debian-9"
    }

    network_interface {
  	network            = var.vpc
  	subnetwork         = var.subnet
        subnetwork_project = var.project 

        alias_ip_range {
            ip_cidr_range         = "/24"
            subnetwork_range_name = "pods"
        }
    }

    scheduling {
        automatic_restart   = false
        on_host_maintenance = "TERMINATE"
        preemptible         = true
    }

    service_account {
        email  = "default"
        scopes = [
            "https://www.googleapis.com/auth/compute",
            "https://www.googleapis.com/auth/devstorage.read_only",
            "https://www.googleapis.com/auth/logging.write",
            "https://www.googleapis.com/auth/monitoring",
        ]
    }
    
    lifecycle {
        create_before_destroy = true
    }
}

resource "google_compute_instance_group_manager" "group_manager" {
    name               = var.group
    base_instance_name = var.group
    project            = var.project 
    target_size        = 2
    zone               = var.region_list[0]
    version {
      name = var.group
      instance_template  = google_compute_instance_template.template_instance.self_link
    }
}

data "google_compute_image" "my_image" {
  family  = "debian-9"
  project = "debian-cloud"
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

resource "google_compute_instance_group_manager" "group" {
  # (resource arguments)
}

