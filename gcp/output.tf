output "attack_lab_web" {
  value = "http://${google_compute_address.csaf.address}:6080/vnc.html"
}

output "defense_lab_web" {
  value = "http://${google_compute_address.csaf.address}:7080/vnc.html"
}

output "monitor_lab_web" {
  value = "http://${google_compute_address.csaf.address}:8080/vnc.html"
}

output "csaf_ssh_access" {
  value = "ssh -i csaf_rsa ubuntu@${google_compute_address.csaf.address}"
}