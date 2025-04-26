resource "google_project" "project_project" {
  name            = var.project_name
  project_id      = var.project_name
  org_id          = var.project_orgid
  billing_account = var.project_billing_account_id
  deletion_policy = "DELETE"
}

resource "google_project_service" "project_google_services" {
  count      = length(var.services_enable)
  project    = var.project_name
  service    = var.services_enable[count.index]
  depends_on = [google_project.project_project]
}
