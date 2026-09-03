resource "azurerm_key_vault" "kv" {
  name                = "kv${var.random_suffix}${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id

  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = var.purge_protection_enabled

  tags = var.tags
}

resource "azurerm_role_assignment" "deployer_kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.deployer_object_id
}

resource "azurerm_role_assignment" "app_tier_kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.app_tier_principal_id
  principal_type       = "ServicePrincipal"

  # VMSS managed identity will be created seconds prior. Entra replication
  # can lag behind, and the existence check then fails with "PrincipalNotFound". 
  # Skipping the check lets the assignment go through; Azure validates it 
  # server-side anyway. 
  skip_service_principal_aad_check = true
}

resource "random_password" "sql_admin_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+{}[]<>:?"
}
# Azure RBAC propagates to the key vault data plane asynchronously. Terraform's depends_on only waits
# for the role assignment resource to be created, not for the RBAC to take effect. Without this pause
# the first apply typically fails with 403 forbidden on the secret write. 
resource "time_sleep" "kv_rbac_propagation" {
  depends_on      = [azurerm_role_assignment.deployer_kv_admin]
  create_duration = "90s"
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin_password.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.deployer_kv_admin, time_sleep.kv_rbac_propagation]
}
