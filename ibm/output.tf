output "public_ip" {
  value = ibm_is_floating_ip.csaf.address
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}