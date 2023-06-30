output "public_ip" {
  value = alicloud_instance.csaf.public_ip
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}