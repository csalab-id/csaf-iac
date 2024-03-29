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
  # Create credential from: https://ca.ovh.com/manager/#/public-cloud/pci/projects/[YOURPROJECTID]/users
  # Generate clouds.yaml & openstack rc file from: https://horizon.cloud.ovh.net/project/api_access/
  # export OS_AUTH_URL="https://auth.cloud.ovh.net/""
  # export OS_USERNAME="yourusername"
  # export OS_PASSWORD="yourpassword"
  # export OS_USER_DOMAIN_NAME="Default"
  # auth_url         = "https://auth.cloud.ovh.net/"
  # user_name        = "yourusername"
  # password         = "yourpassword"
  # user_domain_name = "Default"
}

resource "openstack_compute_keypair_v2" "csaf" {
  name       = var.name
  region     = var.region
  public_key = file("../csaf_rsa.pub")
}

resource "openstack_compute_instance_v2" "csaf" {
  name              = var.name
  flavor_name       = var.package
  region            = var.region
  availability_zone = "nova"
  key_pair          = openstack_compute_keypair_v2.csaf.name
  security_groups   = [openstack_compute_secgroup_v2.csaf.name,]
  user_data         = file("../startup.sh")
  
  block_device {
    uuid                  = "b5004762-45b2-4667-a475-7ae1bcaeb992" # Ubuntu 22.04
    source_type           = "image"
    volume_size           = 100
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    access_network = true
    name           = "Ext-Net"
  }
}

resource "openstack_compute_secgroup_v2" "csaf" {
  name        = var.name
  description = "CSAF Rule"
  region      = var.region

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