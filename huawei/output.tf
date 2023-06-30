output "public_ip" {
  value = huaweicloud_vpc_eip.csaf.address
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}