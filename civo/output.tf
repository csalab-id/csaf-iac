output "public_ip" {
  value = civo_instance.csaf.public_ip
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}