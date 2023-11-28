output "attack_lab_web" {
  value = "http://${azurerm_public_ip.csaf.ip_address}:6080/vnc.html"
}

output "defense_lab_web" {
  value = "http://${azurerm_public_ip.csaf.ip_address}:7080/vnc.html"
}

output "monitor_lab_web" {
  value = "http://${azurerm_public_ip.csaf.ip_address}:8080/vnc.html"
}

output "csaf_ssh_access" {
  value = "ssh -i csaf_rsa ubuntu@${azurerm_public_ip.csaf.ip_address}"
}