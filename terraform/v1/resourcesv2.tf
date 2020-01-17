provider "google" {
  credentials = file("/home/mlt/cloud/accounts/mulatocloud-79bf0469e1be.json")
  project     = "mulatocloud"
  region      = "us-east1"
}

resource "google_compute_network" "app-vpc" {
  name                    = "app-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "app-subnet" {
  name          = "app-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network	= google_compute_network.app-vpc.name
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
  name                     = "app-cluster"
  network                  = google_compute_network.app-vpc.name
  subnetwork		   = google_compute_subnetwork.app-subnet.name
  remove_default_node_pool = true
  initial_node_count       = 2
  location                 = "us-east1-c"
}

resource "google_container_node_pool" "app-cluster-nodes" {
  name       = "app-cluster-node-pool"
  cluster    = google_container_cluster.app-cluster.name
  location   = "us-east1-c"

  autoscaling {
    min_node_count = 2
    max_node_count = 4
  }

  node_config {
    preemptible  = "true"
    disk_size_gb = "30"
    disk_type    = "pd-ssd"
    machine_type = "n1-standard-2"
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/compute",
    ]
  }
}
