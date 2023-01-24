output "public_ip" {
  value = google_compute_address.csalab.address
}

output "subdomain" {
  value = cloudflare_record.csalab.hostname
}