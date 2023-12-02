output "attack_lab_web" {
  value = "http://${scaleway_instance_ip.csaf.address}:6080/vnc.html"
}

output "defense_lab_web" {
  value = "http://${scaleway_instance_ip.csaf.address}:7080/vnc.html"
}

output "monitor_lab_web" {
  value = "http://${scaleway_instance_ip.csaf.address}:8080/vnc.html"
}

output "csaf_ssh_access" {
  value = "ssh -i csaf_rsa root@${scaleway_instance_ip.csaf.address}"
}