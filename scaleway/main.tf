terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.12"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.32"
    }
  }
  required_version = ">= 1.3.0"
}

provider "scaleway" {
  # export SCW_ACCESS_KEY="youraccesskey"
  # export SCW_SECRET_KEY="yoursecretkey"
  # access_key = "youraccesskey"
  # secret_key = "yoursecretkey"
  zone   = var.zone
  region = var.region
}

resource "scaleway_instance_ip" "csaf" {
  project_id = var.project_id
}

resource "scaleway_account_ssh_key" "csaf" {
    name       = var.name
    project_id = var.project_id
    public_key = file("../csaf_rsa.pub")
}

resource "scaleway_instance_security_group" "csaf" {
  project_id              = var.project_id
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  inbound_rule {
    action = "accept"
    port   = "22"
  }

  inbound_rule {
    action = "accept"
    port   = "6080"
  }

  inbound_rule {
    action = "accept"
    port   = "7080"
  }

  inbound_rule {
    action = "accept"
    port   = "8080"
  }
}

resource "scaleway_vpc_private_network" "csaf" {
  name       = var.name
  tags       = [ var.name ]
  zone       = var.zone
  project_id = var.project_id
}

# resource "scaleway_vpc_public_gateway_ip" "csaf" {
# }

# resource "scaleway_vpc_public_gateway_dhcp" "csaf" {
#   subnet             = "10.0.37.0/24"
#   push_default_route = true
# }

# resource "scaleway_vpc_public_gateway" "csaf" {
#   name  = var.name
#   type  = "VPC-GW-S"
#   ip_id = scaleway_vpc_public_gateway_ip.csaf.id
# }

# resource "scaleway_vpc_gateway_network" "csaf" {
#   gateway_id         = scaleway_vpc_public_gateway.csaf.id
#   private_network_id = scaleway_vpc_private_network.csaf.id
#   dhcp_id            = scaleway_vpc_public_gateway_dhcp.csaf.id
#   cleanup_dhcp       = true
#   enable_masquerade  = true
# }

resource "scaleway_instance_server" "csaf" {
  name               = var.name
  project_id         = var.project_id
  type               = var.package
  image              = "ubuntu_jammy"
  tags               = ["development"]
  ip_id              = scaleway_instance_ip.csaf.id
  security_group_id  = scaleway_instance_security_group.csaf.id

  user_data         = {
    cloud-init = filebase64("../startup.sh")
  }

  private_network {
    pn_id = scaleway_vpc_private_network.csaf.id
  }

  root_volume {
    volume_type = "b_ssd"
    size_in_gb  = 100
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
  name    = "scaleway"
  value   = scaleway_instance_ip.csaf.address
  type    = "A"
  proxied = false
  zone_id = data.cloudflare_zone.csaf.id
}