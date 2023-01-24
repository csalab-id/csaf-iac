output "public_ip" {
  value = digitalocean_droplet.csalab.ipv4_address
}

output "subdomain" {
  value = cloudflare_record.csalab.hostname
}