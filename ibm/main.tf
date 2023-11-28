terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.51"
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

resource "ibm_is_vpc" "csaf" {
  name = var.name
}

resource "ibm_is_vpc_address_prefix" "csaf" {
  cidr = "10.0.1.0/24"
  name = var.name
  vpc  = ibm_is_vpc.csaf.id
  zone = var.zone
}

resource "ibm_is_subnet" "csaf" {
  depends_on = [
    ibm_is_vpc_address_prefix.csaf
  ]
  name            = var.name
  vpc             = ibm_is_vpc.csaf.id
  zone            = var.zone
  ipv4_cidr_block = "10.0.1.0/24"
}

resource "ibm_is_security_group" "csaf" {
  name = var.name
  vpc  = ibm_is_vpc.csaf.id
}

resource "ibm_is_security_group_target" "csaf" {
  security_group = ibm_is_security_group.csaf.id
  target         = ibm_is_floating_ip.csaf.target
}

resource "ibm_is_security_group_rule" "csaf" {
  group     = ibm_is_security_group.csaf.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_ssh_key" "csaf" {
  name       = var.name
  public_key = file("../csaf_rsa.pub")
}

resource "ibm_is_instance" "csaf" {
  name      = var.name
  image     = "r006-4861e0a4-8d36-4462-b497-767351f1d371" # Ubuntu 22.04
  profile   = var.package
  vpc       = ibm_is_vpc.csaf.id
  zone      = var.zone
  keys      = [ibm_is_ssh_key.csaf.id]
  user_data = file("../startup.sh")

  primary_network_interface {
    # name   = var.name
    subnet = ibm_is_subnet.csaf.id
  }

  boot_volume {
    name = var.name
    size = 100
  }
}

resource "ibm_is_floating_ip" "csaf" {
  name   = var.name
  target = ibm_is_instance.csaf.primary_network_interface[0].id
}