terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "~> 2.12"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.32"
    }
  }
  required_version = ">= 1.3.0"
}

provider "vultr" {
  # Generate api key: https://my.vultr.com/settings/#settingsapi
  # export VULTR_API_KEY="yourapikey"
  # api_key = "yourapikey"
}

resource "vultr_ssh_key" "csalab" {
  name    = var.name
  ssh_key = file("../csalab_rsa.pub")
}

resource "vultr_instance" "csalab" {
  plan              = var.plan
  os_id             = 1743 # Ubuntu 22.04
  region            = var.region
  label             = var.name
  hostname          = var.name
  enable_ipv6       = false
  backups           = "disabled"
  activation_email  = false
  ddos_protection   = false
  tags              = [var.name]
  firewall_group_id = vultr_firewall_group.csalab.id
  user_data         = file("../startup.sh")
  ssh_key_ids       = [vultr_ssh_key.csalab.id]
  vpc_ids           = [vultr_vpc.csalab.id]
}

resource "vultr_firewall_group" "csalab" {
  description = var.name
}

resource "vultr_firewall_rule" "ssh" {
  firewall_group_id = vultr_firewall_group.csalab.id
  protocol          = "tcp"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  port              = "22"
  ip_type           = "v4"
}

resource "vultr_firewall_rule" "attack" {
  firewall_group_id = vultr_firewall_group.csalab.id
  protocol          = "tcp"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  port              = "6080-8080"
  ip_type           = "v4"
}

resource "vultr_vpc" "csalab" {
  description    = var.name
  region         = var.region
  v4_subnet      = "10.0.37.0"
  v4_subnet_mask = 24
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
  name    = "vultr"
  value   = vultr_instance.csalab.main_ip
  type    = "A"
  proxied = false
  zone_id = data.cloudflare_zone.csalab.id
}