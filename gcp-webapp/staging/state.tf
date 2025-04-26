terraform {
  backend "gcs" {
    bucket = "mulatocloud-staging-state"
    prefix = "init"
  }
}
