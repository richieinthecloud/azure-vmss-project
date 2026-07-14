# i want this subnet to be 10.10.4.0/24

resource "azurerm_mssql_server" "sql_server" {
  name = "sql-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  version = "12.0"
  administrator_login = var.sql_admin_username
  administrator_login_password = random_password.sql_admin_password.result

  public_network_access_enabled = false 

  tags = local.common_tags
}

resource "azurerm_mssql_database" "sql_db" {
  name = "sqldb-vmssproject-${var.environment}"
  server_id = azurerm_mssql_server.sql_server.id

  sku_name = var.sql_database_sku
  zone_redundant = var.sql_zone_redundant

  max_size_gb = 2

  tags = local.common_tags
}

resource "azurerm_private_dns_zone" "sql_private_dns" {
  name = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
  name = "sql-dns-link-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_private_dns.name
  virtual_network_id = azurerm_virtual_network.vnet.id

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "sql_private_endpoint" {
  name = "pe-sql-${local.name_prefix}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id = azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name = "psc-sql-${local.name_prefix}"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    subresource_names = ["sqlServer"]
    is_manual_connection = false
    }

    private_dns_zone_group {
      name = "sql-private-dns-zone-group"

      private_dns_zone_ids = [
        azurerm_private_dns_zone.sql_private_dns.id
      ]
    }

    tags = local.common_tags
}
