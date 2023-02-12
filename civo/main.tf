terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "~> 1.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.32"
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

resource "civo_ssh_key" "csalab"{
  name       = var.name
  public_key = file("../csalab_rsa.pub")
}

resource "civo_instance" "csalab" {
  hostname     = var.name
  size         = var.package
  sshkey_id    = civo_ssh_key.csalab.id
  initial_user = "ubuntu"
  script       = file("../startup.sh")
  network_id   = civo_network.csalab.id
  firewall_id  = civo_firewall.csalab.id
  disk_image   = "9f953761-8b20-4623-8dff-e0c845201966" # Ubuntu 22.04
}

resource "civo_network" "csalab" {
  label = var.name
}

resource "civo_firewall" "csalab" {
  name                 = var.name
  network_id           = civo_network.csalab.id
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

provider "cloudflare" {
  # Generate token (Global API Key) from: https://dash.cloudflare.com/profile/api-tokens
  # export CLOUDFLARE_EMAIL="yourmail"
  # export CLOUDFLARE_API_KEY="yourkey"
  # email   = "yourmail"
  # api_key = "yourkey"
}

data "cloudflare_zone" "csalab" {
  name = var.domain
}

resource "cloudflare_record" "csalab" {
  name    = "civo"
  value   = civo_instance.csalab.public_ip
  type    = "A"
  proxied = false
  zone_id = data.cloudflare_zone.csalab.id
}