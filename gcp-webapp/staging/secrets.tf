resource "google_secret_manager_secret" "project_secret" {
  project   = var.project_name
  secret_id = "project_secret"
  labels = {
    project = "staging"
  }
  replication {
    auto {}
  }
}
