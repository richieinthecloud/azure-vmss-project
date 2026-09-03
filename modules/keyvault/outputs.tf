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

output "key_vault_uri" {
  description = "Base URI of the Key Vault (https://<name>.vault.azure.net/). The app tier builds its secret-fetch URLs from this at boot."
  value       = azurerm_key_vault.kv.vault_uri
}

output "app_gate_password" {
  description = "The plaintext login password for the job tracker demo. Marked sensitive so it never prints in plan/apply output — retrieve it deliberately with: terraform output -raw app_gate_password"
  value       = random_password.app_gate_password.result
  sensitive   = true
}