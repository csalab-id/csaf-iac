terraform {
  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "~> 1.79"
    }
  }
  required_version = ">= 1.3.0"
}

provider "tencentcloud" {
  # Generate from: https://console.tencentcloud.com/cam/capi
  # export TENCENTCLOUD_SECRET_ID="yoursecretid"
  # export TENCENTCLOUD_SECRET_KEY="yoursecretkey"
  # secret_id  = "yoursecretid"
  # secret_key = "yoursecretkey"
  region     = var.region
}

resource "tencentcloud_key_pair" "csaf" {
  key_name   = var.name
  public_key = file("../csaf_rsa.pub")
}

resource "tencentcloud_instance" "csaf" {
  instance_name              = var.name
  hostname                   = var.name
  availability_zone          = var.availability_zone
  image_id                   = "img-487zeit5" # Ubuntu 22.04
  instance_type              = var.package
  key_ids                    = [tencentcloud_key_pair.csaf.id]
  system_disk_type           = "CLOUD_PREMIUM"
  system_disk_size           = 100
  allocate_public_ip         = true
  internet_max_bandwidth_out = 100
  orderly_security_groups    = [tencentcloud_security_group.csaf.id]
  vpc_id                     = tencentcloud_vpc.csaf.id
  subnet_id                  = tencentcloud_subnet.csaf.id
  user_data                  = base64encode(file("../startup.sh"))
}

resource "tencentcloud_route_table" "csaf" {
  name   = var.name
  vpc_id = tencentcloud_vpc.csaf.id
}

resource "tencentcloud_subnet" "csaf" {
  name              = var.name
  cidr_block        = "10.0.37.0/24"
  availability_zone = var.availability_zone
  vpc_id            = tencentcloud_vpc.csaf.id
  route_table_id    = tencentcloud_route_table.csaf.id
}

resource "tencentcloud_vpc" "csaf" {
  name       = var.name
  cidr_block = "10.0.0.0/16"
}

resource "tencentcloud_security_group" "csaf" {
  name        = var.name
  description = "CSA Lab Rules"
}

resource "tencentcloud_security_group_lite_rule" "incoming" {
  security_group_id = tencentcloud_security_group.csaf.id
  ingress = [
    "ACCEPT#0.0.0.0/0#22,6080,7080,8080#TCP",
    "DROP#0.0.0.0/0#ALL#ALL"
  ]

  egress = [
    "ACCEPT#0.0.0.0/0#ALL#ALL"
  ]
}