output "public_ip" {
  value = aws_eip.csaf.public_ip
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}