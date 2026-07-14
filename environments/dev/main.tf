module "network" {

    source = "../../modules/network"

    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name_prefix = locals.name_prefix

    tags = locals.common_tags

    address_space = ["10.10.0.0/16"]
}