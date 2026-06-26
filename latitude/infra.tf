terraform {
  required_providers {
    latitudesh = {
      source  = "latitudesh/latitudesh"
      version = ">= 2.5.0"
    }
  }
}

variable "latitudesh_token" {
  description = "Latitude.sh APIKEY"
  type        = string
  sensitive   = true
}

variable "sshkey" {
  description = "SSH Public Key"
  type        = string
  sensitive   = true
}

provider "latitudesh" {
  auth_token = var.latitudesh_token
}

resource "latitudesh_project" "alex_proj" {
  name              = "alexSRETests"
  description       = "some tests with terraform and curl"
  environment       = "Development" # Development, Production or Staging
  provisioning_type = "on_demand"   # on_demand or reserved
}

resource "latitudesh_ssh_key" "ssh_key" {
  name        = "alex-ssh"
  public_key  = var.sshkey
}

#resource "latitudesh_server" "sre-bm-alex-test" {
#  billing          = "monthly"
#  hostname         = "sre-bm-alex-test"
#  operating_system = "ubuntu_24_04_x64_lts"
#  plan             = "f4-metal-small"
#  project          = latitudesh_project.alex_proj.id  # You can use the project id or slug
#  site             = "ASH"
#  ssh_keys         = [latitudesh_ssh_key.ssh_key.id]
#}
#
#output "server_ip" {
#  value = latitudesh_server.sre-bm-alex-test.primary_ipv4
#}
#

#resource "latitudesh_virtual_machine" "bastion" {
#  name             = "sre-alex-bastion"
#  project          = latitudesh_project.alex_proj.id
#  plan             = "vm-small"
#  operating_system = "ubuntu_24_04_x64_lts"
#  ssh_keys         = [latitudesh_ssh_key.ssh_key.id]
#}
#
#resource "latitudesh_virtual_machine" "app" {
#  name             = "sre-alex-app"
#  project          = latitudesh_project.alex_proj.id
#  plan             = "vm-small"
#  operating_system = "ubuntu_24_04_x64_lts"
#  ssh_keys         = [latitudesh_ssh_key.ssh_key.id]
#}
#
#output "bastion_ip" {
#  value = latitudesh_virtual_machine.bastion.primary_ipv4
#}
#
#output "app_ip" {
#  value = latitudesh_virtual_machine.app.primary_ipv4
#}
