output "key_vault_id" {
  description = "ID of the Key Vault."
  value       = azurerm_key_vault.kv.id
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = azurerm_key_vault.kv.name
}

output "sql_admin_password" {
  description = "Generated SQL administrator password."
  value       = random_password.sql_admin_password.result
  sensitive   = true
}