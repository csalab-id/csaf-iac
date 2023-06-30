output "public_ip" {
  value = vultr_instance.csaf.main_ip
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}