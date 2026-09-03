# NAT Gateway for explicit outbound internet access for the private tiers

# why?: the web and app tier VMSS have no public IPs, which is by design. 
# however, they still need to initiate outbound connections at boot:
# apt-git, to install nginx, python and ODBC driver
# packages.microsoft.com, for the SQL ODBC driver
# our blob storage to pull the app artifact
# our vault to read secrets and authenticate to other services

# production deployment would need one NAT gateway per zone
# this project is for demo purposes so it only utilizes one

resource "azurerm_public_ip" "nat" {
    name = "pip-nat-${var.name_prefix}"
    location = var.location
    resource_group_name = var.resource_group_name

    # static + standard are REQUIRED for our purposes
    allocation_method = "Static"
    sku = "Standard"

    tags = var.tags
}

resource "azurerm_nat_gateway" "nat" {
    name = "nat-${var.name_prefix}"
    location = var.location
    resource_group_name = var.resource_group_name
    sku_name = "Standard" # the only sku nat gateway offers

    idle_timeout_in_minutes = 4 # default is 4, but you may need to raise it if you have long-lived connections
    tags = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat" {
    nat_gateway_id = azurerm_nat_gateway.nat.id
    public_ip_address_id = azurerm_public_ip.nat.id
}

# only the web and app tiers get egress
# applying least privilege principles to networking. Only that subnets that genuinely need to reach the internet can

resource "azurerm_subnet_nat_gateway_association" "web" {
    subnet_id = var.web_subnet_id
    nat_gateway_id = azurerm_nat_gateway.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "app" {
    subnet_id = var.app_subnet_id
    nat_gateway_id = azurerm_nat_gateway.nat.id
}