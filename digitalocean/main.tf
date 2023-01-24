terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.25"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.32"
    }
  }
  required_version = ">= 1.3.0"
}

provider "digitalocean" {
  # Generate token from: https://cloud.digitalocean.com/account/api/tokens
  # export DIGITALOCEAN_TOKEN="yourtoken"
  # token = "yourtoken"
}

resource "digitalocean_ssh_key" "csalab" {
  name       = var.name
  public_key = file("../csalab_rsa.pub")
}

resource "digitalocean_droplet" "csalab" {
  name      = var.name
  image     = "ubuntu-22-04-x64"
  size      = var.package
  region    = var.region
  ssh_keys  = [digitalocean_ssh_key.csalab.fingerprint]
  vpc_uuid  = digitalocean_vpc.csalab.id
  user_data = file("../startup.sh")
}

resource "digitalocean_firewall" "csalab" {
  name = var.name

  droplet_ids = [
    digitalocean_droplet.csalab.id,
  ]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [
      "0.0.0.0/0",
    ]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "6080"
    source_addresses = [
      "0.0.0.0/0",
    ]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "7080"
    source_addresses = [
      "0.0.0.0/0",
    ]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "8080"
    source_addresses = [
      "0.0.0.0/0",
    ]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = [
      "0.0.0.0/0",
    ]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = [
      "0.0.0.0/0",
    ]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = [
      "0.0.0.0/0",
    ]
  }
}

resource "digitalocean_vpc" "csalab" {
  name     = var.name
  region   = var.region
  ip_range = "10.0.37.0/24"
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
  name    = "digitalocean"
  value   = digitalocean_droplet.csalab.ipv4_address
  type    = "A"
  proxied = false
  zone_id = data.cloudflare_zone.csalab.id
}