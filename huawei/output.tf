output "public_ip" {
  value = huaweicloud_vpc_eip.csalab.address
}

output "subdomain" {
  value = cloudflare_record.csalab.hostname
}