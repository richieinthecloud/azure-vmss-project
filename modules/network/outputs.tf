output "web_subnet_id" {
    value = azurerm_subnet.web_subnet.id
}

output "app_subnet_id" {
    value = azurerm_subnet.app_subnet.id
}

output "gateway_subnet_id" {
    value = azurerm_subnet.gateway_subnet.id
}