output "public_ip" {
  value = hcloud_server.csaf.ipv4_address
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}