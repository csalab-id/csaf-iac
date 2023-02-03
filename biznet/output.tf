output "public_ip" {
  value = openstack_networking_floatingip_v2.csalab.address
}

output "subdomain" {
  value = cloudflare_record.csalab.hostname
}