output "public_ip" {
  value = openstack_networking_floatingip_v2.csaf.address
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}