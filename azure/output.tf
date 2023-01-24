output "public_ip" {
  value = azurerm_public_ip.csalab.ip_address
}

output "subdomain" {
  value = cloudflare_record.csalab.hostname
}