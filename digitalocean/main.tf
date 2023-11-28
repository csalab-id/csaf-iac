terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.25"
    }
  }
  required_version = ">= 1.3.0"
}

provider "digitalocean" {
  # Generate token from: https://cloud.digitalocean.com/account/api/tokens
  # export DIGITALOCEAN_TOKEN="yourtoken"
  # token = "yourtoken"
}

resource "digitalocean_ssh_key" "csaf" {
  name       = var.name
  public_key = file("../csaf_rsa.pub")
}

resource "digitalocean_droplet" "csaf" {
  name      = var.name
  image     = "ubuntu-22-04-x64"
  size      = var.package
  region    = var.region
  ssh_keys  = [digitalocean_ssh_key.csaf.fingerprint]
  vpc_uuid  = digitalocean_vpc.csaf.id
  user_data = file("../startup.sh")
}

resource "digitalocean_firewall" "csaf" {
  name = var.name

  droplet_ids = [
    digitalocean_droplet.csaf.id,
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
    port_range       = "6080-8080"
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

resource "digitalocean_vpc" "csaf" {
  name     = var.name
  region   = var.region
  ip_range = "10.0.37.0/24"
}