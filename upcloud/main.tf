terraform {
  required_providers {
    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = "~> 2.8"
    }
  }
  required_version = ">= 1.3.0"
}

provider "upcloud" {
  # Register from here: https://signup.upcloud.com/
  # export UPCLOUD_USERNAME="yourusername"
  # export UPCLOUD_PASSWORD="yourpassword"
  # username = "yourusername"
  # password = "yourpassword"
}

resource "upcloud_server" "csaf" {
  hostname  = var.name
  title     = var.name
  zone      = var.zone
  plan      = var.plan
  firewall  = true
  metadata  = true
  user_data = file("../startup.sh")

  template {
    size    = 100
    storage = "01000000-0000-4000-8000-000030220200" # Ubuntu 22.04
  }

  network_interface {
    ip_address_family = "IPv4"
    type              = "public"
  }

  network_interface {
    ip_address_family = "IPv4"
    type              = "private"
    network           = upcloud_network.csaf.id
  }

  login {
    user = "ubuntu"
    keys = [
      file("../csaf_rsa.pub"),
    ]
  }
}

resource "upcloud_firewall_rules" "csaf" {
  server_id = upcloud_server.csaf.id

  firewall_rule {
    action                    = "accept"
    destination_address_end   = "255.255.255.255"
    destination_address_start = "0.0.0.0"
    destination_port_start    = "22"
    destination_port_end      = "22"
    direction                 = "in"
    family                    = "IPv4"
    protocol                  = "tcp"
  }

  firewall_rule {
    action                    = "accept"
    destination_address_end   = "255.255.255.255"
    destination_address_start = "0.0.0.0"
    destination_port_start    = "6080"
    destination_port_end      = "8080"
    direction                 = "in"
    family                    = "IPv4"
    protocol                  = "tcp"
  }

  firewall_rule {
    action    = "drop"
    direction = "in"
  }
}

resource "upcloud_network" "csaf" {
  name   = var.name
  zone   = var.zone
  router = upcloud_router.csaf.id

  ip_network {
    address            = "10.0.37.0/24"
    dhcp               = true
    dhcp_default_route = false
    family             = "IPv4"
    gateway            = "10.0.37.1"
  }
}

resource "upcloud_router" "csaf" {
  name = var.name
}