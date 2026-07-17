data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name_prefix}"
  location = var.location

  tags = local.common_tags
}

# -------------------------------------
# Networking
# -------------------------------------

module "network" {
  source = "../../modules/network"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  address_space                  = var.address_space
  appgw_subnet_prefix            = var.appgw_subnet_prefix
  webvmss_subnet_prefix          = var.web_subnet_prefix
  appvmss_subnet_prefix          = var.app_subnet_prefix
  private_endpoint_subnet_prefix = var.private_endpoint_subnet_prefix
  bastion_subnet_prefix          = var.bastion_subnet_prefix
}

# -------------------------------------
# External Load Balancer (Application Gateway + WAF)
# -------------------------------------

module "app_gateway" {
  source = "../../modules/app_gateway"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  subnet_id          = module.network.appgw_subnet_id
  waf_mode           = var.waf_mode
  min_capacity       = var.appgw_min_capacity
  max_capacity       = var.appgw_max_capacity
  availability_zones = var.availability_zones
}

# -------------------------------------
# Internal Load Balancer (web tier -> app tier)
# -------------------------------------

module "internal_lb" {
  source = "../../modules/internal_lb"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  subnet_id          = module.network.app_subnet_id
  availability_zones = var.availability_zones
}

# -------------------------------------
# Web tier VMSS
# -------------------------------------

module "web_vmss" {
  source = "../../modules/web_vmss"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  subnet_id                     = module.network.web_subnet_id
  appgw_backend_address_pool_id = module.app_gateway.backend_address_pool_id
  internal_lb_frontend_ip       = module.internal_lb.frontend_private_ip

  admin_username     = var.admin_username
  ssh_public_key     = var.ssh_public_key
  vmss_sku           = var.vmss_sku
  instance_count     = var.web_initial_instance_count
  resume_name        = var.resume_name
  availability_zones = var.availability_zones
}

# -------------------------------------
# App tier VMSS
# -------------------------------------

module "app_vmss" {
  source = "../../modules/app_vmss"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  subnet_id                           = module.network.app_subnet_id
  internal_lb_backend_address_pool_id = module.internal_lb.backend_address_pool_id

  admin_username     = var.admin_username
  ssh_public_key     = var.ssh_public_key
  vmss_sku           = var.vmss_sku
  instance_count     = var.app_initial_instance_count
  availability_zones = var.availability_zones
}

# -------------------------------------
# Key Vault
# -------------------------------------

module "keyvault" {
  source = "../../modules/keyvault"

  name_prefix         = local.name_prefix
  environment         = var.environment
  random_suffix       = random_integer.suffix.result
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  tenant_id             = data.azurerm_client_config.current.tenant_id
  deployer_object_id    = data.azurerm_client_config.current.object_id
  app_tier_principal_id = module.app_vmss.principal_id

  purge_protection_enabled = var.kv_purge_protection_enabled
}

# -------------------------------------
# Database (Azure SQL, private endpoint)
# -------------------------------------

module "database" {
  source = "../../modules/database"

  name_prefix         = local.name_prefix
  environment         = var.environment
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  vnet_id                    = module.network.vnet_id
  private_endpoint_subnet_id = module.network.private_endpoint_subnet_id

  sql_admin_username = var.sql_admin_username
  sql_admin_password = module.keyvault.sql_admin_password
  sql_database_sku   = var.sql_database_sku
  sql_zone_redundant = var.sql_zone_redundant
}

# -------------------------------------
# Bastion
# -------------------------------------

module "bastion" {
  source = "../../modules/bastion"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  subnet_id = module.network.bastion_subnet_id
}

# -------------------------------------
# Monitoring (autoscale, action group, alerts)
# -------------------------------------

module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags

  alert_email = var.alert_email

  web_vmss_id                = module.web_vmss.vmss_id
  web_initial_instance_count = var.web_initial_instance_count
  web_min_instance_count     = var.web_min_instance_count
  web_max_instance_count     = var.web_max_instance_count

  app_vmss_id                = module.app_vmss.vmss_id
  app_initial_instance_count = var.app_initial_instance_count
  app_min_instance_count     = var.app_min_instance_count
  app_max_instance_count     = var.app_max_instance_count
}