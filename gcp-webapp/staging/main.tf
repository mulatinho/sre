locals {
  project_name               = "mulatocloud-staging"
  project_region             = "us-central1"
  project_orgid              = local.project_secret.project_orgid
  project_billing_account_id = local.project_secret.project_billing_account_id
  project_environments       = ["dev", "prod"]
  project_secret             = jsondecode(data.google_secret_manager_secret_version.project_secret.secret_data)
  project_subnets = [
    { name = "db", cidr = "10.1.1.0/24" },
    { name = "app", cidr = "10.1.2.0/24" },
  ]
}

data "google_secret_manager_secret_version" "project_secret" {
  project = local.project_name
  secret  = "project_secret"
}

module "init" {
  project_name               = local.project_name
  project_region             = local.project_region
  project_orgid              = local.project_orgid
  project_billing_account_id = local.project_billing_account_id
  source                     = "../modules/init"
}

module "network" {
  count               = length(local.project_environments)
  project_name        = local.project_name
  project_environment = local.project_environments[count.index]
  project_subnets     = local.project_subnets
  project_region      = local.project_region
  source              = "../modules/network"
}