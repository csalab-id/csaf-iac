output "public_ip" {
  value = google_compute_address.csaf.address
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}