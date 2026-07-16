output "public_ip_address" {
    description = "Public IP address of the Application Gateway."
    value = azurerm_public_ip.appgw.ip_address
}

output "application_gateway_id" {
  description = "ID of the Application Gateway."
  value = azurerm_application_gateway.appgw.id
}

output "backend_address_pool_id" {
    description = "ID of the Application Gateway backend address pool that the web tier VMSS attaches to."
    value = one(azurerm_application_gateway.appgw.backend_address_pool).id
}