output "public_ip" {
  value = upcloud_server.csaf.network_interface[0].ip_address
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}