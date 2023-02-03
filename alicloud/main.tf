terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.195"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.32"
    }
  }
  required_version = ">= 1.3.0"
}

provider "alicloud" {
  # Generate key from: https://ram.console.aliyun.com/manage/ak
  # export ALICLOUD_ACCESS_KEY="youraccesskey"
  # export ALICLOUD_SECRET_KEY="yoursecretkey"
  # access_key = "youraccesskey"
  # secret_key = "yoursecretkey"
  region     = var.region
}

resource "alicloud_key_pair" "csalab" {
  key_pair_name = var.name
  public_key    = file("../csalab_rsa.pub")
}

resource "alicloud_security_group" "csalab" {
  name        = var.name
  description = "CSA Lab security group"
  vpc_id      = alicloud_vpc.csalab.id
}

resource "alicloud_security_group_rule" "ssh" {
  description       = "SSH Rule"
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.csalab.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "csalab" {
  description       = "CSA Lab Rule"
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "6080/8080"
  priority          = 2
  security_group_id = alicloud_security_group.csalab.id
  cidr_ip           = "0.0.0.0/0"
}

data "alicloud_zones" "csalab" {
  available_disk_category     = "cloud_efficiency"
  available_resource_creation = "VSwitch"
}

resource "alicloud_vpc" "csalab" {
  cidr_block = "10.0.0.0/16"
}

resource "alicloud_vswitch" "csalab" {
  vpc_id       = alicloud_vpc.csalab.id
  cidr_block   = "10.0.37.0/24"
  zone_id      = data.alicloud_zones.csalab.zones[0].id
  vswitch_name = var.name
}

resource "alicloud_instance" "csalab" {
  instance_name              = var.name
  host_name                  = var.name
  description                = "CSA Lab instance"
  availability_zone          = data.alicloud_zones.csalab.zones[0].id
  security_groups            = [alicloud_security_group.csalab.id]
  key_name                   = alicloud_key_pair.csalab.key_name
  instance_type              = var.package
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = var.name
  system_disk_description    = "CSA Lab disk"
  system_disk_size           = 100
  image_id                   = "ubuntu_22_04_x64_20G_alibase_20221130.vhd"
  vswitch_id                 = alicloud_vswitch.csalab.id
  internet_max_bandwidth_out = 100
  user_data                  = file("../startup.sh")
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
  name    = "alicloud"
  value   = alicloud_instance.csalab.public_ip
  type    = "A"
  proxied = false
  zone_id = data.cloudflare_zone.csalab.id
}