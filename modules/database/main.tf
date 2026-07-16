resource "azurerm_mssql_server" "sql_server" {
  name                = "sql-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = "12.0"

  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  public_network_access_enabled = false

  tags = var.tags
}

resource "azurerm_mssql_database" "sql_db" {
  name      = "sqldb-vmssproject-${var.environment}"
  server_id = azurerm_mssql_server.sql_server.id

  sku_name       = var.sql_database_sku
  zone_redundant = var.sql_zone_redundant

  max_size_gb = 2

  tags = var.tags
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "sql-dns-link-${var.name_prefix}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = var.vnet_id

  tags = var.tags
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-sql-${var.name_prefix}"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "sql-private-dns-zone-group"

    private_dns_zone_ids = [
      azurerm_private_dns_zone.sql.id
    ]
  }

  tags = var.tags
}