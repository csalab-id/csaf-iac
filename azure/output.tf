output "public_ip" {
  value = azurerm_public_ip.csaf.ip_address
}

output "subdomain" {
  value = cloudflare_record.csaf.hostname
}