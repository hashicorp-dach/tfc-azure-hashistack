output "Public_Server_IP" {
  value = azurerm_public_ip.hashistack_server_public_ip.*.ip_address
}

output "Public_Client_IP" {
  value = azurerm_public_ip.hashistack_client_public_ip.*.ip_address
}