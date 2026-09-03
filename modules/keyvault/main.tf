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
}

resource "random_password" "sql_admin_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+{}[]<>:?"
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin_password.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_role_assignment.deployer_kv_admin
  ]
}
# ----------------------------------
# job tracker password gate
# why a hash instead of a password?: the app tier fetches this at boot. If it fetched a plaintext password,
# that plaintext would sit in the process memory and in the app's config files on disk.
# Any bug that dumps configs (stack trace, debug endpoint, a log line) leaks a working credential. 
# By storing only a bcrypt hash, the app can still verify a passwo rd someone types
# and the app can never reveal the password, because it only has the hash

resource "random_password" "app_gate_password" {
  length = 20
  special = false # letters and digits only
}

resource "azurerm_key_vault_secret" "app_gate_password_hash" {
  name = "app-gate-password-hash"

  # Terraform's built-in bcrypt function. Cost factor 10 is the default and is good for this instance
  value = bcrypt(random_password.app_gate_password.result)
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.deployer_kv_admin]

  # bcrypt() is salted, which means it produces a different hash every time it runs 
  # without this ignore_changes, every 'terraform plan' would show this secret as changed,
  # every apply would write a new version, and your app tier would roll instances on every apply unnecessarily. 

  # ignore_changes tell Terraform: Create this once, then stop looking at its value. To deliberately rotate the password, 
  # taint the random_password resources
  #   terraform taint random_password.app_gate_password
  lifecycle {
    ignore_changes = [value]
  }
}

# when you log in, the app gives your browser a cooking proving it. The cookie is signed with this key (HMAC-SHA256).
# without a sig, anyone could forge a cookie that says "I'm logged in" and skip the password entirely. 

# this lives in Key Vault rather than being generated per-instance because all instances must agree on it
# otherwise, a cookie issued by one instance would be rejected by another and the load balancer would log you out randomly on every other request. 
# Common problem with stateless sessions. 

resource "random_password" "app_session_secret" {
  length = 64
  special = false
}

resource "azurerm_key_vault_secret" "app_session_secret" {
  name = "app-session-secret"
  value = random_password.app_session_secret.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.deployer_kv_admin]
} 