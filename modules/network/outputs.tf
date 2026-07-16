output "vnet_id" {
    description = "ID of the Virtual Network"
    value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
    description = "Name of the Virtual Network"
    value = azurerm_virtual_network.vnet.name
}

output "appgw_subnet_id" {
    description = "ID of the Application Gateway Subnet"
    value = azurerm_subnet.appgw_subnet.id
}

output "webvmss_subnet_id" {
    description = "ID of the Web VMSS Subnet"
    value = azurerm_subnet.webvmss_subnet.id
}

output "appvmss_subnet_id" {
    description = "ID of the App VMSS Subnet"
    value = azurerm_subnet.appvmss_subnet.id
}

output "private_endpoint_subnet_id" {
    description = "ID of the Private Endpoint Subnet"
    value = azurerm_subnet.private_endpoint_subnet.id
}

output "bastion_subnet_id" {
    description = "ID of the Bastion Subnet"
    value = azurerm_subnet.bastion_subnet.id
}