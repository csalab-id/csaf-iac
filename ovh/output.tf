output "attack_lab_web" {
  value = "http://${openstack_compute_instance_v2.csaf.access_ip_v4}:6080/vnc.html"
}

output "defense_lab_web" {
  value = "http://${openstack_compute_instance_v2.csaf.access_ip_v4}:7080/vnc.html"
}

output "monitor_lab_web" {
  value = "http://${openstack_compute_instance_v2.csaf.access_ip_v4}:8080/vnc.html"
}

output "csaf_ssh_access" {
  value = "ssh -i csaf_rsa ubuntu@${openstack_compute_instance_v2.csaf.access_ip_v4}"
}