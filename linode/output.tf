output "public_ip" {
  value = linode_instance.csalab.ip_address
}

output "subdomain" {
  value = cloudflare_record.csalab.hostname
}