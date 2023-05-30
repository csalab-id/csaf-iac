output "public_ip" {
  value = scaleway_instance_ip.csalab.address
}

output "subdomain" {
  value = cloudflare_record.csalab.hostname
}