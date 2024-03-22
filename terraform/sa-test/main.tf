provider "google" {
  project = "mulatocloud"
  region  = "us-central1"
}

resource "google_service_account" "stg_service" {
  account_id   = "stg-service"
  display_name = "Staging Service Account"
  project      = "mulatocloud-staging"
}

