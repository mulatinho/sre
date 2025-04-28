locals {
  project_name               = var.project_name
  project_region             = "us-central1"
  project_billing_account_id = var.project_billing_account_id
  project_environments       = ["dev", "prod"]
  project_subnets = [
    { name = "db", cidr = "10.1.1.0/24" },
    { name = "app", cidr = "10.1.2.0/24" },
  ]
  project_orgid = "810980746305"
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
