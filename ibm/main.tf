terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.51"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.32"
    }
  }
  required_version = ">= 1.3.0"
}

provider "ibm" {
  # Generate API from: https://cloud.ibm.com/iam/apikeys
  # export IC_API_KEY="yourapikey"
  # ibmcloud_api_key = "yourapikey"
  region           = var.region
}

resource "ibm_is_vpc" "csalab" {
  name = var.name
}

resource "ibm_is_vpc_address_prefix" "csalab" {
  cidr = "10.0.1.0/24"
  name = var.name
  vpc  = ibm_is_vpc.csalab.id
  zone = var.zone
}

resource "ibm_is_subnet" "csalab" {
  depends_on = [
    ibm_is_vpc_address_prefix.csalab
  ]
  name            = var.name
  vpc             = ibm_is_vpc.csalab.id
  zone            = var.zone
  ipv4_cidr_block = "10.0.1.0/24"
}

resource "ibm_is_security_group" "csalab" {
  name = var.name
  vpc  = ibm_is_vpc.csalab.id
}

resource "ibm_is_security_group_target" "csalab" {
  security_group = ibm_is_security_group.csalab.id
  target         = ibm_is_floating_ip.csalab.target
}

resource "ibm_is_security_group_rule" "csalab" {
  group     = ibm_is_security_group.csalab.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_ssh_key" "csalab" {
  name       = var.name
  public_key = file("../csalab_rsa.pub")
}

resource "ibm_is_instance" "csalab" {
  name      = var.name
  image     = "r006-4861e0a4-8d36-4462-b497-767351f1d371" # Ubuntu 22.04
  profile   = var.package
  vpc       = ibm_is_vpc.csalab.id
  zone      = var.zone
  keys      = [ibm_is_ssh_key.csalab.id]
  user_data = file("../startup.sh")

  primary_network_interface {
    # name   = var.name
    subnet = ibm_is_subnet.csalab.id
  }

  boot_volume {
    name = var.name
    size = 100
  }
}

resource "ibm_is_floating_ip" "csalab" {
  name   = var.name
  target = ibm_is_instance.csalab.primary_network_interface[0].id
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
  name    = "ibm"
  value   = ibm_is_floating_ip.csalab.address
  type    = "A"
  proxied = false
  zone_id = data.cloudflare_zone.csalab.id
}