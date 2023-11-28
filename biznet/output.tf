output "attack_lab_web" {
  value = "http://${openstack_networking_floatingip_v2.csaf.address}:6080/vnc.html"
}

output "defense_lab_web" {
  value = "http://${openstack_networking_floatingip_v2.csaf.address}:7080/vnc.html"
}

output "monitor_lab_web" {
  value = "http://${openstack_networking_floatingip_v2.csaf.address}:8080/vnc.html"
}

output "csaf_ssh_access" {
  value = "ssh -i csaf_rsa ubuntu@${openstack_networking_floatingip_v2.csaf.address}"
}