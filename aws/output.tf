output "public_ip" {
  value = aws_eip.csalab.public_ip
}

output "subdomain" {
  value = cloudflare_record.csalab.hostname
}