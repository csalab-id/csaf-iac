output "public_ip" {
  value = vultr_instance.csalab.main_ip
}

output "subdomain" {
  value = cloudflare_record.csalab.hostname
}