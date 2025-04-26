data "google_project" "project_project" {
  project_id = var.project_name
}

resource "google_compute_network" "project_network" {
  name                            = var.project_environment
  project                         = data.google_project.project_project.name
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "project_subnetwork" {
  count         = length(var.project_subnets)
  name          = join("-", [data.google_project.project_project.name, google_compute_network.project_network.name, var.project_subnets[count.index].name])
  project       = data.google_project.project_project.name
  network       = google_compute_network.project_network.self_link
  region        = var.project_region
  ip_cidr_range = var.project_subnets[count.index].cidr
}

resource "google_compute_router" "project_router" {
  network = google_compute_network.project_network.self_link
  name    = join("-", [data.google_project.project_project.name, google_compute_network.project_network.name, "cloud-router"])
  region  = var.project_region
  project = data.google_project.project_project.name
}

resource "google_compute_router_nat" "project_router_nat" {
  region                              = var.project_region
  name                                = join("-", [data.google_project.project_project.name, google_compute_network.project_network.name, "cloud-router-nat"])
  router                              = google_compute_router.project_router.name
  nat_ip_allocate_option              = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  enable_endpoint_independent_mapping = false
  project                             = data.google_project.project_project.name
}
