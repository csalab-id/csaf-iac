output "public_ip" {
  value = openstack_compute_instance_v2.csaf.access_ip_v4
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}