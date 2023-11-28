terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.90"
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
  #
  # Set your project:
  # export GOOGLE_PROJECT="google-project"
  # project = "google-project"
  region  = var.region
  zone    = var.zone
}

data "google_client_openid_userinfo" "csaf" {}

resource "google_os_login_ssh_public_key" "csaf" {
  user    = data.google_client_openid_userinfo.csaf.email
  key     = file("../csaf_rsa.pub")
}

resource "google_compute_instance" "csaf" {
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
    ssh-keys = "ubuntu:${google_os_login_ssh_public_key.csaf.key}"
  }

  network_interface {
    network = google_compute_network.public-csaf.name
    access_config {
      nat_ip = google_compute_address.csaf.address
    }
  }

  network_interface {
    network    = google_compute_network.local-csaf.name
    subnetwork = google_compute_subnetwork.csaf.name
  }
}

resource "google_compute_firewall" "csaf" {
  name    = "allow-csaf"
  network = google_compute_network.public-csaf.name

  allow {
    protocol = "tcp"
    ports    = ["22", "6080", "7080", "8080"]
  }

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_network" "local-csaf" {
  name = "local-${var.name}"
}

resource "google_compute_network" "public-csaf" {
  name = "public-${var.name}"
}

resource "google_compute_subnetwork" "csaf" {
  name          = var.name
  ip_cidr_range = "10.0.37.0/24"
  region        = var.region
  network       = google_compute_network.local-csaf.self_link
}

resource "google_compute_address" "csaf" {
  name   = var.name
  region = var.region
}