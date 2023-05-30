output "public_ip" {
  value = ibm_is_floating_ip.csalab.address
}

output "subdomain" {
  value = cloudflare_record.csalab.hostname
}