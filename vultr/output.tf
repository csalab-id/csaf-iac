output "attack_lab_web" {
  value = "http://${vultr_instance.csaf.main_ip}:6080/vnc.html"
}

output "defense_lab_web" {
  value = "http://${vultr_instance.csaf.main_ip}:7080/vnc.html"
}

output "monitor_lab_web" {
  value = "http://${vultr_instance.csaf.main_ip}:8080/vnc.html"
}

output "csaf_ssh_access" {
  value = "ssh -i csaf_rsa ubuntu@${vultr_instance.csaf.main_ip}"
}