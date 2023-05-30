terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.90"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.32"
    }
  }
  required_version = ">= 1.3.0"
}

provider "google" {
  # Generate Service Account from: https://console.cloud.google.com/iam-admin/serviceaccounts
  # Using file example:
  # export GOOGLE_APPLICATION_CREDENTIALS="yourcredentialfile.json"
  # credentials = file("yourcredentialfile.json")
  #
  # Using string example:
  # export GOOGLE_CREDENTIALS='{"your": "credentialstring"}'
  # credentials = <<-EOT
  # {"your": "credentialstring"}
  # EOT
  project = var.project
  region  = var.region
  zone    = var.zone
}

data "google_client_openid_userinfo" "csalab" {}

resource "google_os_login_ssh_public_key" "csalab" {
  user    = data.google_client_openid_userinfo.csalab.email
  key     = file("../csalab_rsa.pub")
  project = var.project
}

resource "google_compute_instance" "csalab" {
  name                    = var.name
  machine_type            = var.package
  zone                    = var.zone
  metadata_startup_script = file("../startup.sh")

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-jammy-v20221206"
      size  = 100
      type  = "pd-balanced"
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${google_os_login_ssh_public_key.csalab.key}"
  }

  network_interface {
    network = google_compute_network.public-csalab.name
    access_config {
      nat_ip = google_compute_address.csalab.address
    }
  }

  network_interface {
    network    = google_compute_network.local-csalab.name
    subnetwork = google_compute_subnetwork.csalab.name
  }
}

resource "google_compute_firewall" "csalab" {
  name    = "allow-csalab"
  network = google_compute_network.public-csalab.name

  allow {
    protocol = "tcp"
    ports    = ["22", "6080", "7080", "8080"]
  }

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_network" "local-csalab" {
  name = "local-${var.name}"
}

resource "google_compute_network" "public-csalab" {
  name = "public-${var.name}"
}

resource "google_compute_subnetwork" "csalab" {
  name          = var.name
  ip_cidr_range = "10.0.37.0/24"
  region        = var.region
  network       = google_compute_network.local-csalab.self_link
}

resource "google_compute_address" "csalab" {
  name   = var.name
  region = var.region
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
  name    = "gcp"
  value   = google_compute_address.csalab.address
  type    = "A"
  proxied = false
  zone_id = data.cloudflare_zone.csalab.id
}
