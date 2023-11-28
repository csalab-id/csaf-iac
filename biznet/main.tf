terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.49"
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

resource "openstack_compute_keypair_v2" "csaf" {
  name       = var.name
  region     = var.region
  public_key = file("../csaf_rsa.pub")
}

resource "openstack_compute_instance_v2" "csaf" {
  name              = var.name
  image_name        = "Ubuntu 22.04 LTS"
  flavor_name       = var.package
  region            = var.region
  availability_zone = "az-01"
  key_pair          = openstack_compute_keypair_v2.csaf.name
  security_groups   = ["default", openstack_compute_secgroup_v2.csaf.name]
  user_data         = file("../startup.sh")
  network {
    access_network = true
    name           = openstack_networking_network_v2.csaf.name
  }
}

resource "openstack_networking_network_v2" "csaf" {
  name           = var.name
  admin_state_up = "true"
}

resource "openstack_networking_port_v2" "csaf" {
  name           = var.name
  network_id     = openstack_networking_network_v2.csaf.id
  admin_state_up = "true"
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.csaf.id
  }
}

resource "openstack_networking_subnet_v2" "csaf" {
  name            = var.name
  network_id      = openstack_networking_network_v2.csaf.id
  cidr            = "10.0.37.0/24"
  ip_version      = 4
}

resource "openstack_networking_router_v2" "csaf" {
  name                = var.name
  external_network_id = "70229857-9658-416a-96cf-27f19cfa8606"
}

resource "openstack_networking_router_interface_v2" "csaf" {
  router_id = openstack_networking_router_v2.csaf.id
  subnet_id = openstack_networking_subnet_v2.csaf.id
}

resource "openstack_networking_floatingip_v2" "csaf" {
  pool = "Public_Network"
}

resource "openstack_compute_floatingip_associate_v2" "csaf" {
  floating_ip = openstack_networking_floatingip_v2.csaf.address
  instance_id = openstack_compute_instance_v2.csaf.id
}

resource "openstack_compute_secgroup_v2" "csaf" {
  name        = var.name
  description = "CSAF Rule"

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