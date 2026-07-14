output "resource_group_name" {
  description = "Name of the created resource group."
  value = azurerm_resource_group.rg.name
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway."
  value = azurerm_public_ip.appgw_pip.ip_address
}

output "website_url" {
  description = "HTTP URL for the resume website through Application Gateway."
  value = "http://${azurerm_public_ip.appgw_pip.ip_address}"
}

output "bastion_name" {
  description = "Azure Bastion host name."
  value = azurerm_bastion_host.bastion.name
}

output "vmss_name"{
    description = "Virtual Machine Scale Set name."
    value = azurerm_linux_virtual_machine_scale_set.vmss.name
}

output "sql_server_fqdn"{
    description = "Azure SQL Server FQDN."
    value = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}

output "sql_database_name" {
    description = "Azure SQL Database name."
    value = azurerm_mssql_database.sql_db.name
}

output "key_vault_name" {
    description = "Key Vault name."
    value = azurerm_key_vault.kv.name
}

output "storage_static_website_endpoint" {
    description = "Static website endpoint for the storage account."
    value = azurerm_storage_account.static.primary_web_endpoint 
<<<<<<< HEAD
}
=======
}
>>>>>>> 8a04d2a (Refactoring Terraform code to better match Terraform best practices)
