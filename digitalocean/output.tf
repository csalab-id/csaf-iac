output "attack_lab_web" {
  value = "http://${digitalocean_droplet.csaf.ipv4_address}:6080/vnc.html"
}

output "defense_lab_web" {
  value = "http://${digitalocean_droplet.csaf.ipv4_address}:7080/vnc.html"
}

output "monitor_lab_web" {
  value = "http://${digitalocean_droplet.csaf.ipv4_address}:8080/vnc.html"
}

output "csaf_ssh_access" {
  value = "ssh -i csaf_rsa root@${digitalocean_droplet.csaf.ipv4_address}"
}