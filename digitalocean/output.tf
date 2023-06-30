output "public_ip" {
  value = digitalocean_droplet.csaf.ipv4_address
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}