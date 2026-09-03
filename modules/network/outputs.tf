output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "appgw_subnet_id" {
  description = "ID of the Application Gateway Subnet"
  value       = azurerm_subnet.appgw.id
}

output "web_subnet_id" {
  description = "Web tier subnet ID. Sourced from the NAT association so consumers cannot be created until outbound internet exists."
  value       = azurerm_subnet_nat_gateway_association.web.subnet_id
}

output "app_subnet_id" {
  description = "App tier subnet ID. Sourced from the NAT association so consumers cannot be created until outbound internet exists."
  value       = azurerm_subnet_nat_gateway_association.app.subnet_id
}

output "private_endpoint_subnet_id" {
  description = "ID of the Private Endpoint Subnet"
  value       = azurerm_subnet.private_endpoint_subnet.id
}

output "bastion_subnet_id" {
  description = "ID of the Bastion Subnet"
  value       = azurerm_subnet.bastion_subnet.id
}
