terraform {
  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "~> 1.79"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.32"
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

resource "tencentcloud_key_pair" "csalab" {
  key_name   = var.name
  public_key = file("../csalab_rsa.pub")
}

resource "tencentcloud_instance" "csalab" {
  instance_name              = var.name
  hostname                   = var.name
  availability_zone          = var.availability_zone
  image_id                   = "img-487zeit5" # Ubuntu 22.04
  instance_type              = var.package
  key_ids                    = [tencentcloud_key_pair.csalab.id]
  system_disk_type           = "CLOUD_PREMIUM"
  system_disk_size           = 100
  allocate_public_ip         = true
  internet_max_bandwidth_out = 100
  orderly_security_groups    = [tencentcloud_security_group.csalab.id]
  vpc_id                     = tencentcloud_vpc.csalab.id
  subnet_id                  = tencentcloud_subnet.csalab.id
  user_data                  = base64encode(file("../startup.sh"))
}

resource "tencentcloud_route_table" "csalab" {
  name   = var.name
  vpc_id = tencentcloud_vpc.csalab.id
}

resource "tencentcloud_subnet" "csalab" {
  name              = var.name
  cidr_block        = "10.0.37.0/24"
  availability_zone = var.availability_zone
  vpc_id            = tencentcloud_vpc.csalab.id
  route_table_id    = tencentcloud_route_table.csalab.id
}

resource "tencentcloud_vpc" "csalab" {
  name       = var.name
  cidr_block = "10.0.0.0/16"
}

resource "tencentcloud_security_group" "csalab" {
  name        = var.name
  description = "CSA Lab Rules"
}

resource "tencentcloud_security_group_rule" "incoming" {
  security_group_id = tencentcloud_security_group.csalab.id
  type              = "ingress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "TCP"
  port_range        = "22,6080,7080,8080"
  policy            = "accept"
}

resource "tencentcloud_security_group_rule" "outgoing" {
  security_group_id = tencentcloud_security_group.csalab.id
  type              = "egress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "TCP"
  policy            = "accept"
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
  name    = "tencent"
  value   = tencentcloud_instance.csalab.public_ip
  type    = "A"
  proxied = false
  zone_id = data.cloudflare_zone.csalab.id
}