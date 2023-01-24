output "public_ip" {
  value = alicloud_instance.csalab.public_ip
}

output "subdomain" {
  value = cloudflare_record.csalab.hostname
}