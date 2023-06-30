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

data "linode_profile" "csaf" {}

resource "linode_sshkey" "csaf" {
  label   = var.name
  ssh_key = chomp(file("../csaf_rsa.pub"))
}

resource "linode_stackscript" "csaf" {
  label       = var.name
  description = "Deploy CSAF"
  script      = file("../startup.sh")
  images      = ["linode/ubuntu22.04"]
  rev_note    = "v1.0"
}

resource "linode_instance"  "csaf" {
  label          = var.name
  group          = var.name
  region         = var.region
  type           = var.package
}

resource "linode_instance_disk" "csaf" {
  label            = "boot"
  linode_id        = linode_instance.csaf.id
  size             = 100000 # 100 GB
  image            = "linode/ubuntu22.04"
  authorized_keys  = [linode_sshkey.csaf.ssh_key]
  authorized_users = [data.linode_profile.csaf.username]
  root_pass        = "CSAF_Admin@"
  stackscript_id   = linode_stackscript.csaf.id
}

resource "linode_instance_config" "boot_config" {
  label       = "boot_config"
  linode_id   = linode_instance.csaf.id
  root_device = "/dev/sda"
  kernel      = "linode/latest-64bit"
  booted      = true

  devices {
    sda {
      disk_id = linode_instance_disk.csaf.id
    }
  }
}

resource "linode_firewall" "csaf" {
  label           = var.name
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
  linodes         = [linode_instance.csaf.id]

  inbound {
    label    = "ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
  }

  inbound {
    label    = "csaf"
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

data "cloudflare_zone" "csaf" {
  name = var.domain
}

resource "cloudflare_record" "csaf" {
  name    = "linode"
  value   = linode_instance.csaf.ip_address
  type    = "A"
  proxied = false
  zone_id = data.cloudflare_zone.csaf.id
}