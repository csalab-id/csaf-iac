output "public_ip" {
  value = hcloud_server.csalab.ipv4_address
}

output "subdomain" {
  value = cloudflare_record.csalab.hostname
}