terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.36"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.32"
    }
  }
  required_version = ">= 1.3.0"
}

provider "hcloud" {
  # Generate token from: https://console.hetzner.cloud/projects/[yourprojectid]/security/tokens
  # export HCLOUD_TOKEN="yourtoken"
  # token = "yourtoken"
}

resource "hcloud_ssh_key" "csalab" {
  name       = var.name
  public_key = file("../csalab_rsa.pub")
}

resource "hcloud_server" "csalab" {
  name         = var.name
  image        = "ubuntu-22.04"
  server_type  = var.package
  location     = var.location
  user_data    = file("../startup.sh")
  ssh_keys     = [hcloud_ssh_key.csalab.name]

  network {
    network_id = hcloud_network.csalab.id
  }

  depends_on = [
    hcloud_network_subnet.csalab
  ]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
}

resource "hcloud_network" "csalab" {
  name     = var.name
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "csalab" {
  type         = "cloud"
  network_id   = hcloud_network.csalab.id
  network_zone = var.zone
  ip_range     = "10.0.37.0/24"
}

resource "hcloud_firewall" "csalab" {
  name = var.name
  rule {
    description = "Allow SSH"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = [
      "0.0.0.0/0"
    ]
  }

  rule {
    description = "Allow CSA Lab"
    direction   = "in"
    protocol    = "tcp"
    port        = "6080-8080"
    source_ips  = [
      "0.0.0.0/0"
    ]
  }
}

resource "hcloud_firewall_attachment" "csalab" {
  firewall_id = hcloud_firewall.csalab.id
  server_ids  = [hcloud_server.csalab.id]
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
  name    = "hetzner"
  value   = hcloud_server.csalab.ipv4_address
  type    = "A"
  proxied = false
  zone_id = data.cloudflare_zone.csalab.id
}