terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      version = "~> 1.29"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.32"
    }
  }
  required_version = ">= 1.3.0"
}

provider  "linode" {
  # Generate token from: https://cloud.linode.com/profile/tokens
  # export LINODE_TOKEN="yourtoken"
  # token = "yourtoken"
}

data "linode_profile" "csalab" {}

resource "linode_sshkey" "csalab" {
  label   = var.name
  ssh_key = chomp(file("../csalab_rsa.pub"))
}

resource "linode_stackscript" "csalab" {
  label       = var.name
  description = "Deploy CSA Lab"
  script      = file("../startup.sh")
  images      = ["linode/ubuntu22.04"]
  rev_note    = "v1.0"
}

resource "linode_instance"  "csalab" {
  label          = var.name
  group          = var.name
  region         = var.region
  type           = var.package
}

resource "linode_instance_disk" "csalab" {
  label            = "boot"
  linode_id        = linode_instance.csalab.id
  size             = 100000 # 100 GB
  image            = "linode/ubuntu22.04"
  authorized_keys  = [linode_sshkey.csalab.ssh_key]
  authorized_users = [data.linode_profile.csalab.username]
  root_pass        = "CSA_Admin"
  stackscript_id   = linode_stackscript.csalab.id
}

resource "linode_instance_config" "boot_config" {
  label       = "boot_config"
  linode_id   = linode_instance.csalab.id
  root_device = "/dev/sda"
  kernel      = "linode/latest-64bit"
  booted      = true

  devices {
    sda {
      disk_id = linode_instance_disk.csalab.id
    }
  }
}

resource "linode_firewall" "csalab" {
  label           = var.name
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
  linodes         = [linode_instance.csalab.id]

  inbound {
    label    = "ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
  }

  inbound {
    label    = "csalab"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "6080-8080"
    ipv4     = ["0.0.0.0/0"]
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
  name    = "linode"
  value   = linode_instance.csalab.ip_address
  type    = "A"
  proxied = false
  zone_id = data.cloudflare_zone.csalab.id
}