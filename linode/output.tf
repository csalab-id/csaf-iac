output "public_ip" {
  value = linode_instance.csaf.ip_address
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}