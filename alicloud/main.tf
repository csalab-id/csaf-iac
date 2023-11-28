terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.195"
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

resource "alicloud_key_pair" "csaf" {
  key_pair_name = var.name
  public_key    = file("../csaf_rsa.pub")
}

resource "alicloud_security_group" "csaf" {
  name        = var.name
  description = "CSAF Security Group"
  vpc_id      = alicloud_vpc.csaf.id
}

resource "alicloud_security_group_rule" "ssh" {
  description       = "SSH Rule"
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.csaf.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "csaf" {
  description       = "CSAF Rule"
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "6080/8080"
  priority          = 2
  security_group_id = alicloud_security_group.csaf.id
  cidr_ip           = "0.0.0.0/0"
}

data "alicloud_zones" "csaf" {
  available_disk_category     = "cloud_efficiency"
  available_resource_creation = "VSwitch"
}

resource "alicloud_vpc" "csaf" {
  cidr_block = "10.0.0.0/16"
}

resource "alicloud_vswitch" "csaf" {
  vpc_id       = alicloud_vpc.csaf.id
  cidr_block   = "10.0.37.0/24"
  zone_id      = data.alicloud_zones.csaf.zones[0].id
  vswitch_name = var.name
}

resource "alicloud_instance" "csaf" {
  instance_name              = var.name
  host_name                  = var.name
  description                = "CSAF Instance"
  availability_zone          = data.alicloud_zones.csaf.zones[0].id
  security_groups            = [alicloud_security_group.csaf.id]
  key_name                   = alicloud_key_pair.csaf.key_pair_name
  instance_type              = var.package
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = var.name
  system_disk_description    = "CSAF Disk"
  system_disk_size           = 100
  image_id                   = "ubuntu_22_04_x64_20G_alibase_20221130.vhd"
  vswitch_id                 = alicloud_vswitch.csaf.id
  internet_max_bandwidth_out = 100
  user_data                  = file("../startup.sh")
}