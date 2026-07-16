resource "azurerm_virtual_network" "vnet" {
  name = "vnet-${var.name_prefix}"
  location = var.location
  resource_group_name = var.resource_group_name
  address_space = var.address_space

  tags = var.tags
}

resource "azurerm_subnet" "appgw" {
  name = "subnet-appgw"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = var.appgw_subnet_prefix
}

resource "azurerm_subnet" "web-vmss" {
  name = "web-vmss-subnet"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = var.webvmss_subnet_prefix
}

resource "azurerm_subnet" "app-vmss" {
  name = "app-vmss-subnet"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = var.appvmss_subnet_prefix
}

resource "azurerm_subnet" "private_endpoint_subnet" {
  name = "subnet-pe"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = var.private_endpoint_subnet_prefix

  private_endpoint_network_policies = "Disabled"
}

# Azure Bastion requires a subnet specifically name AzureBastionSubnet

resource "azurerm_subnet" "bastion_subnet" {
  name = "AzureBastionSubnet"
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = var.bastion_subnet_prefix
}

# --------------------
# NSG: Application Gateway subnet
# --------------------

resource "azurerm_network_security_group" "appgw_nsg" {
  name = "nsg-appgw-${var.name_prefix}"
  location = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name = "Allow-HTTP-HTTPS-inbound"
    priority = 200
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = ["80", "443"]
    source_address_prefix = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Allow-GatewayManager-Inbound"
    priority = 210
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "65200-65535"
    source_address_prefix = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Allow-HealthProbe-Inbound"
    priority = 220
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Allow-AppGW-to-VMSS"
    priority = 230
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = azurerm_subnet.appgw.address_prefixes[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Allow-AzureLoadBalancer-Inbound"
    priority = 240
    direction = "Inbound"
    access = "Allow"
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "appgw" {
  subnet_id = azurerm_subnet.appgw.id
  network_security_group_id = azurerm_network_security_group.appgw.id
}

#NSG: Web tier subnet VMSS

resource "azurerm_network_security_group" "web_vmss" {
  name = "nsg-web-${var.name_prefix}"
  location = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name = "Allow-HTTP-From-AppGW"
    priority = 200
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = var.appgw_subnet_prefix[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Allow-SSH-From-Bastion"
    priority = 210
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = var.bastion_subnet_prefix[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Deny-Internet-Inbound"
    priority = 300
    direction = "Inbound"
    access = "Deny"
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "Internet"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "web_vmss" {
  subnet_id = azurerm_subnet.web-vmss.id
  network_security_group_id = azurerm_network_security_group.web_vmss.id
}

# NSGs for App tier subnet VMSS

resource "azurerm_network_security_group" "app_vmss" {
  name = "nsg-app-${var.name_prefix}"
  location = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name = "Allow-HTTP-From-Web"
    priority = 200
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = var.webvmss_subnet_prefix[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Allow-AzureLoadBalancer-Probe-Inbound"
    priority = 210
    direction = "Inbound"
    access = "Allow"
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Allow-SSH-From-Bastion"
    priority = 220
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = var.bastion_subnet_prefix[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Deny-Internet-Inbound"
    priority = 300
    direction = "Inbound"
    access = "Deny"
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "Internet"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "app_vmss" {
  subnet_id = azurerm_subnet.app-vmss.id
  network_security_group_id = azurerm_network_security_group.app_vmss.id
}

# NSG for private endpoint subnet
# Only app tier may reach the SQL private endpoint on 1433. 

resource "azurerm_network_security_group" "private_endpoint_nsg" {
  name = "nsg-pe-${var.name_prefix}"
  location = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name = "Allow-SQL-From-App"
    priority = 200
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "1433"
    source_address_prefix = var.appvmss_subnet_prefix[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Deny-All-Other-Inbound"
    priority = 300
    direction = "Inbound"
    access = "Deny"
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "private_endpoint_nsg" {
  subnet_id = azurerm_subnet.private_endpoint_subnet.id
  network_security_group_id = azurerm_network_security_group.private_endpoint_nsg.id
}

# NSG for Azure Bastion subnet

resource "azurerm_network_security_group" "bastion_nsg" {
  name = "nsg-bastion-${var.name_prefix}"
  location = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name = "Allow-HTTPS-Inbound"
    priority = 200
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "443"
    source_address_prefix = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Allow-GatewayManager"
    priority = 210
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "443"
    source_address_prefix = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Allow-AzureLoadBalancer-Inbound"
    priority = 220
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "443"
    source_address_prefix = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "Allow-BastionHostComms-Inbound"
    priority = 230
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = ["8080", "5701"]
    source_address_prefix = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name = "Allow-SSH-RDP-Outbound"
    priority = 200
    direction = "Outbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = ["22", "3389"]
    source_address_prefix = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name = "Allow-AzureCloud-Outbound"
    priority = 210
    direction = "Outbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "443"
    source_address_prefix = "*"
    destination_address_prefix = "AzureCloud"
  }

  security_rule {
    name = "Allow-BastionHostComes-Outbound"
    priority = 220
    direction = "Outbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = ["8080", "5701"]
    source_address_prefix = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name = "Allow-GetCertificate-Outbound"
    priority = 230
    direction = "Outbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = "*"
    destination_address_prefix = "Internet"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "bastion_nsg" {
  subnet_id = azurerm_subnet.bastion_subnet.id
  network_security_group_id = azurerm_network_security_group.bastion_nsg.id
}