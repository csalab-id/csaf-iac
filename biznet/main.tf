terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.49"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.32"
    }
  }
  required_version = ">= 1.3.0"
}

provider "openstack" {
  # Register credential from: https://portal.biznetgio.com/user/register
  # Generate clouds.yaml & openstack rc file from: https://horizon.neo.id/project/api_access/
  # export OS_AUTH_URL="https://keystone.jkt-2.neo.id:13000"
  # export OS_USERNAME="youremail"
  # export OS_PASSWORD="yourpassword"
  # export OS_USER_DOMAIN_NAME="neo.id"
  # export OS_PROJECT_ID="yourprojectid"
  # auth_url         = "https://keystone.jkt-2.neo.id:13000"
  # user_name        = "youremail"
  # password         = "yourpassword"
  # user_domain_name = "neo.id"
  # tenant_id        = "yourprojectid"
}

resource "openstack_compute_keypair_v2" "csalab" {
  name       = var.name
  region     = var.region
  public_key = file("../csalab_rsa.pub")
}

resource "openstack_compute_instance_v2" "csalab" {
  name              = var.name
  image_name        = "Ubuntu 22.04 LTS"
  flavor_name       = var.package
  region            = var.region
  availability_zone = "az-01"
  key_pair          = openstack_compute_keypair_v2.csalab.name
  security_groups   = ["default", openstack_compute_secgroup_v2.csalab.name]
  user_data         = file("../startup.sh")
  network {
    access_network = true
    name           = openstack_networking_network_v2.csalab.name
  }
}

resource "openstack_networking_network_v2" "csalab" {
  name           = var.name
  admin_state_up = "true"
}

resource "openstack_networking_port_v2" "csalab" {
  name           = var.name
  network_id     = openstack_networking_network_v2.csalab.id
  admin_state_up = "true"
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.csalab.id
  }
}

resource "openstack_networking_subnet_v2" "csalab" {
  name            = var.name
  network_id      = openstack_networking_network_v2.csalab.id
  cidr            = "10.0.37.0/24"
  ip_version      = 4
}

resource "openstack_networking_router_v2" "csalab" {
  name                = var.name
  external_network_id = "70229857-9658-416a-96cf-27f19cfa8606"
}

resource "openstack_networking_router_interface_v2" "csalab" {
  router_id = openstack_networking_router_v2.csalab.id
  subnet_id = openstack_networking_subnet_v2.csalab.id
}

resource "openstack_networking_floatingip_v2" "csalab" {
  pool = "Public_Network"
}

resource "openstack_compute_floatingip_associate_v2" "csalab" {
  floating_ip = openstack_networking_floatingip_v2.csalab.address
  instance_id = openstack_compute_instance_v2.csalab.id
}

resource "openstack_compute_secgroup_v2" "csalab" {
  name        = var.name
  description = "CSA Lab Rule"

  rule {
    ip_protocol = "tcp"
    from_port   = "22"
    to_port     = "22"
    cidr        = "0.0.0.0/0"
  }

  rule {
    ip_protocol = "tcp"
    from_port   = "6080"
    to_port     = "8080"
    cidr        = "0.0.0.0/0"
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
  name    = "biznet"
  value   = openstack_networking_floatingip_v2.csalab.address
  type    = "A"
  proxied = false
  zone_id = data.cloudflare_zone.csalab.id
}