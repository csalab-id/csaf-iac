output "attack_lab_web" {
  value = "http://${tencentcloud_instance.csaf.public_ip}:6080/vnc.html"
}

output "defense_lab_web" {
  value = "http://${tencentcloud_instance.csaf.public_ip}:7080/vnc.html"
}

output "monitor_lab_web" {
  value = "http://${tencentcloud_instance.csaf.public_ip}:8080/vnc.html"
}

output "csaf_ssh_access" {
  value = "ssh -i csaf_rsa ubuntu@${tencentcloud_instance.csaf.public_ip}"
}