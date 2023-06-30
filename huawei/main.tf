terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.44"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.32"
    }
  }
  required_version = ">= 1.3.0"
}

provider "huaweicloud" {
  # Generate access key from: https://console-intl.huaweicloud.com/iam/#/mine/accessKey
  # export HW_ACCESS_KEY="youraccesskey"
  # export HW_SECRET_KEY="yoursecretkey"
  # access_key = "youraccesskey"
  # secret_key = "yoursecretkey"
  region     = var.region
}

resource "huaweicloud_compute_keypair" "csaf" {
  name       = var.name
  public_key = file("../csaf_rsa.pub")
}

resource "huaweicloud_compute_instance" "csaf" {
  name               = var.name
  image_name         = "Ubuntu 22.04 server 64bit"
  flavor_id          = var.package
  key_pair           = huaweicloud_compute_keypair.csaf.name
  security_groups    = [huaweicloud_networking_secgroup.csaf.name]
  region             = var.region
  availability_zone  = var.zone
  system_disk_size   = 100
  system_disk_type   = "SAS"
  user_data          = file("../startup.sh")

  network {
    uuid = huaweicloud_vpc_subnet.csaf.id
  }
}

resource "huaweicloud_networking_secgroup" "csaf" {
  name        = var.name
  description = "CSAF Security Group"
}

resource "huaweicloud_networking_secgroup_rule" "ssh" {
  security_group_id = huaweicloud_networking_secgroup.csaf.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "csaf" {
  security_group_id = huaweicloud_networking_secgroup.csaf.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6080
  port_range_max    = 8080
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_vpc_eip" "csaf" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = var.name
    size        = 300
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_compute_eip_associate" "csaf" {
  public_ip   = huaweicloud_vpc_eip.csaf.address
  instance_id = huaweicloud_compute_instance.csaf.id
}

resource "huaweicloud_vpc" "csaf" {
  name = var.name
  cidr = "10.0.0.0/16"
}

resource "huaweicloud_vpc_subnet" "csaf" {
  name       = var.name
  cidr       = "10.0.37.0/24"
  gateway_ip = "10.0.37.1"
  vpc_id     = huaweicloud_vpc.csaf.id
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
  name    = "huawei"
  value   = huaweicloud_vpc_eip.csaf.address
  type    = "A"
  proxied = false
  zone_id = data.cloudflare_zone.csaf.id
}
