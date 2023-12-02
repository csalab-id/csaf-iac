output "attack_lab_web" {
  value = "http://${huaweicloud_vpc_eip.csaf.address}:6080/vnc.html"
}

output "defense_lab_web" {
  value = "http://${huaweicloud_vpc_eip.csaf.address}:7080/vnc.html"
}

output "monitor_lab_web" {
  value = "http://${huaweicloud_vpc_eip.csaf.address}:8080/vnc.html"
}

output "csaf_ssh_access" {
  value = "ssh -i csaf_rsa root@${huaweicloud_vpc_eip.csaf.address}"
}