output "resource_group_name" {
  description = "Name of the created resource group."
  value       = azurerm_resource_group.rg.name
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway."
  value       = module.app_gateway.public_ip_address
}

output "website_url" {
  description = "HTTP URL for the resume website through the Application Gateway."
  value       = "http://${module.app_gateway.public_ip_address}"
}

output "internal_lb_frontend_ip" {
  description = "Private frontend IP of the internal load balancer fronting the app tier."
  value       = module.internal_lb.frontend_private_ip
}

output "bastion_name" {
  description = "Azure Bastion host name."
  value       = module.bastion.bastion_name
}

output "web_vmss_name" {
  description = "Web tier Virtual Machine Scale Set name."
  value       = module.web_vmss.vmss_name
}

output "app_vmss_name" {
  description = "App tier Virtual Machine Scale Set name."
  value       = module.app_vmss.vmss_name
}

output "sql_server_fqdn" {
  description = "Azure SQL Server FQDN."
  value       = module.database.sql_server_fqdn
}

output "sql_database_name" {
  description = "Azure SQL Database name."
  value       = module.database.sql_database_name
}

output "key_vault_name" {
  description = "Key Vault name."
  value       = module.keyvault.key_vault_name
}