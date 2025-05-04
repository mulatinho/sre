provider "google" {
  project = local.project_id
  region  = local.region
}

terraform {
  backend "gcs" {
    bucket = "mulatocloud-tfstate"
    prefix = "mulatocloud"
  }
}

resource "google_compute_network" "default_vpc" {
  name                    = local.vpc_name
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "default_subnet" {
  name          = local.default_subnetwork_name
  network       = google_compute_network.default_vpc.id
  ip_cidr_range = local.default_cidr_range
  region        = local.region
}

resource "google_compute_subnetwork" "k8s_subnet" {
  name                     = local.k8s_subnetwork_name
  network                  = google_compute_network.default_vpc.id
  ip_cidr_range            = local.k8s_cidr_range
  region                   = local.region
  private_ip_google_access = "true"

  secondary_ip_range {
    range_name    = local.pods_range_name
    ip_cidr_range = local.pods_cidr_range
  }
  secondary_ip_range {
    range_name    = local.svc_range_name
    ip_cidr_range = local.svc_cidr_range
  }
}

resource "google_compute_router" "default_route" {
  name    = local.router_name
  network = google_compute_network.default_vpc.id
}

resource "google_compute_router_nat" "default_route" {
  name                               = local.router_nat_name
  router                             = google_compute_router.default_route.name
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option             = "AUTO_ONLY"
}

resource "google_service_account" "k8s_sa" {
  account_id   = local.k8s_sa_name
  display_name = local.k8s_sa_display_name
}

resource "google_container_cluster" "mulatocluster" {
  name                     = local.cluster_name
  location                 = local.location
  initial_node_count       = local.initial_node_count
  network                  = google_compute_network.default_vpc.name
  subnetwork               = google_compute_subnetwork.k8s_subnet.name
  remove_default_node_pool = true
  private_cluster_config {
    enable_private_nodes = true
  }
  release_channel {
    channel = "STABLE"
  }
  node_config {
    preemptible  = true
    machine_type = var.machine.type
  }
  monitoring_config {
    enable_components = []
  }
  monitoring_service = "none"
}

resource "google_container_node_pool" "default" {
  cluster            = google_container_cluster.mulatocluster.name
  name               = var.machine.name
  location           = var.machine.location
  initial_node_count = var.machine.node_count
  node_config {
    preemptible     = true
    machine_type    = var.machine.type
    disk_size_gb    = var.machine.size
    service_account = google_service_account.k8s_sa.email
    tags            = ["default-pool", "k8s"]
    labels = {
      team = "sre"
    }
  }
  network_config {
    pod_range = local.pods_range_name
  }
}

resource "google_service_account" "vms_sa" {
  account_id   = local.vms_sa_name
  display_name = local.vms_sa_display_name
}

resource "google_compute_firewall" "ssh_fw" {
  name    = "ssh-fw"
  network = google_compute_network.default_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  source_tags   = ["redis"]
}

resource "google_compute_instance" "redis" {
  name         = "redis"
  machine_type = var.machine.type
  zone         = "us-central1-a"
  metadata = {
    ssh-keys = "${local.ssh_username}:${file(local.ssh_pub_key_path)}"
  }
  network_interface {
    network    = google_compute_network.default_vpc.id
    subnetwork = google_compute_subnetwork.default_subnet.id
  }
  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240110"
      size  = 100
    }
  }
  
  tags = ["redis"]
  labels = {
    team = "sre"
    role = "redis"
  }
}


# output "redis_ip" {
#  value = "${google_compute_instance.redis.network_interface.0.access_config.0.nat_ip}"
# }