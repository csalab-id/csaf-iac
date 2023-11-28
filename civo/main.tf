terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "~> 1.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "civo" {
  # Generate token from: https://dashboard.civo.com/security
  # export CIVO_TOKEN="yourtoken"
  # token  = "yourtoken"
  region = var.region
}

resource "civo_ssh_key" "csaf"{
  name       = var.name
  public_key = file("../csaf_rsa.pub")
}

resource "civo_instance" "csaf" {
  hostname     = var.name
  size         = var.package
  sshkey_id    = civo_ssh_key.csaf.id
  initial_user = "ubuntu"
  script       = file("../startup.sh")
  network_id   = civo_network.csaf.id
  firewall_id  = civo_firewall.csaf.id
  disk_image   = "9f953761-8b20-4623-8dff-e0c845201966" # Ubuntu 22.04
}

resource "civo_network" "csaf" {
  label = var.name
}

resource "civo_firewall" "csaf" {
  name                 = var.name
  network_id           = civo_network.csaf.id
  create_default_rules = false
  ingress_rule {
    label      = "ssh"
    protocol   = "tcp"
    port_range = "22"
    cidr       = ["0.0.0.0/0"]
    action     = "allow"
  }

  ingress_rule {
    label      = "ssh"
    protocol   = "tcp"
    port_range = "6080-8080"
    cidr       = ["0.0.0.0/0"]
    action     = "allow"
  }

  egress_rule {
    label      = "all"
    protocol   = "tcp"
    port_range = "1-65535"
    cidr       = ["0.0.0.0/0"]
    action     = "allow"
  }
}