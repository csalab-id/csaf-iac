output "public_ip" {
  value = scaleway_instance_ip.csaf.address
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}