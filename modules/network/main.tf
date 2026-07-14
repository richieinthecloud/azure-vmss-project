resource "azurerm_virtual_network" "vnet" {
  name = "vnet-${local.name_prefix}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "appgw_subnet" {
  name = "subnet-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "vmss_subnet" {
  name = "subnet-vmss"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.10.2.0/24"]
}

resource "azurerm_subnet" "private_endpoint_subnet" {
  name = "subnet-pe"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.10.3.0/24"]

  private_endpoint_network_policies = "Disabled"
}

# Azure Bastion requires a subnet specifically name AzureBastionSubnet
resource "azurerm_subnet" "bastion_subnet" {
  name = "AzureBastionSubnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.10.4.0/26"]
}

resource "azurerm_network_security_group" "vmss_nsg" {
  name = "nsg-vmss-${local.name_prefix}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.common_tags
}

resource "azurerm_network_security_rule" "allow_http_from_appgw" {
  name = "Allow-HTTP-From-AppGW"
  priority = 100
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "80"
  source_address_prefix = "10.10.1.0/24"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vmss_nsg.name
}

resource "azurerm_network_security_rule" "allow_ssh_from_bastion" {
  name = "Allow-SSH-From-Bastion"
  priority = 110
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "22"
  source_address_prefix = "10.10.4.0/26"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vmss_nsg.name
}

resource "azurerm_network_security_rule" "deny_ssh_from_internet" {
  name = "Deny-SSH-From-Internet"
  priority = 200
  direction = "Inbound"
  access = "Deny"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "22"
  source_address_prefix = "Internet"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vmss_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "vmss_nsg_assoc" {
    subnet_id = azurerm_subnet.vmss_subnet.id
    network_security_group_id = azurerm_network_security_group.vmss_nsg.id
}