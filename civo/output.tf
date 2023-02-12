output "public_ip" {
  value = civo_instance.csalab.public_ip
}

output "subdomain" {
  value = cloudflare_record.csalab.hostname
}