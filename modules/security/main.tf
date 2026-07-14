# bastion configs will fall under security
# i want the bastion subnet to be 10.0.5.0/26

resource "azurerm_public_ip" "bastion_pip" {
  name = "pip-bastion-${local.name_prefix}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Static"
  sku = "Standard"

  tags = local.common_tags
}

resource "azurerm_bastion_host" "bastion" {
  name = "bastion-${local.name_prefix}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "bastion-ip-config"
    subnet_id = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = local.common_tags
}

# web tier NSGs will allow application gateway to communicate over port 80 and 443
# deny all other internet traffic to the web vmss from the internet

# app tier nsg will allow web tier to speak to app tier only

# database tier NSGs will allow only app tier to communicate with SQL using private endpoint


