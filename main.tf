terraform {
  required_version = ">=1.6.0"
  # terraform core version

  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4.0"
        # azurerm provider version
    }

    random = {
        source = "hashicorp/random"
        version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "random_integer" "suffix" {
  min = 10000
  max = 99999
  # this is so I don't have to worry about giving my resource globally unique names
  # the Azure Resource Manager will instead do it for me
}

locals {
  name_prefix = "${var.project_name}-${var.environment}-${random_integer.suffix.result}"

  common_tags = {
    Project = var.project_name
    Environment = var.environment
    ManagedBy = "Terraform"
    Owner = var.owner 
  }
}

# -------------------------------------
# Resource Group
# -------------------------------------

resource "azurerm_resource_group" "rg" {
  name = "rg-${local.name_prefix}"
  location = var.location

  tags = local.common_tags
}

# -------------------------------------
# Networking
# -------------------------------------

resource "azurerm_virtual_network" "vnet" {
  name = "vnet-${local.name_prefix}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space = ["10.10.0.0/16"]

  tags = local.common_tags
}

resource "azurerm_subnet" "appgw_subnet" {
  name = "subnet-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "vmss_subnet" {
  name = "subnet-vmss"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.10.2.0/24"]
}

resource "azurerm_subnet" "private_endpoint_subnet" {
  name = "subnet-pe"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.10.3.0/24"]

  private_endpoint_network_policies = "Disabled"
}

# Azure Bastion requires a subnet specifically name AzureBastionSubnet
resource "azurerm_subnet" "bastion_subnet" {
  name = "AzureBastionSubnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.10.4.0/26"]
}

# -------------------------------------
# NSG for VMSS Subnet
# -------------------------------------

resource "azurerm_network_security_group" "vmss_nsg" {
  name = "nsg-vmss-${local.name_prefix}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.common_tags
}

resource "azurerm_network_security_rule" "allow_http_from_appgw" {
  name = "Allow-HTTP-From-AppGW"
  priority = 100
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "80"
  source_address_prefix = "10.10.1.0/24"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vmss_nsg.name
}

resource "azurerm_network_security_rule" "allow_ssh_from_bastion" {
  name = "Allow-SSH-From-Bastion"
  priority = 110
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "22"
  source_address_prefix = "10.10.4.0/26"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vmss_nsg.name
}

resource "azurerm_network_security_rule" "deny_ssh_from_internet" {
  name = "Deny-SSH-From-Internet"
  priority = 200
  direction = "Inbound"
  access = "Deny"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "22"
  source_address_prefix = "Internet"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vmss_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "vmss_nsg_assoc" {
    subnet_id = azurerm_subnet.vmss_subnet.id
    network_security_group_id = azurerm_network_security_group.vmss_nsg.id
}

# -------------------------------------
# Public IP for App GW
# -------------------------------------

resource "azurerm_public_ip" "appgw_pip" {
  name = "pip-appgw-${local.name_prefix}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Static"
  sku = "Standard"
  zones = ["1", "2", "3"]

  tags = local.common_tags
}

# -------------------------------------
# Application Gateway WAF v2
# -------------------------------------

resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name = "waf-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  policy_settings {
    enabled = true
    mode = "Prevention"
    request_body_check = true
    max_request_body_size_in_kb = 128
    file_upload_limit_in_mb = 100
  }

  managed_rules {
    managed_rule_set {
      type = "OWASP"
      version = "3.2"
    }
  }

  tags = local.common_tags
}

resource "azurerm_application_gateway" "appgw" {
  name = "appgw-${local.name_prefix}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  gateway_ip_configuration {
    name = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_ip_configuration {
    name = "appgw-public-frontend"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  frontend_port {
    name = "frontend-port-80"
    port = 80
  }

  backend_address_pool {
    name = "vmss-backend-pool"
  }

  backend_http_settings {
    name = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    path = "/"
    port = 80
    protocol = "Http"
    request_timeout = 30
  }

  http_listener {
    name = "http-listener"
    frontend_ip_configuration_name = "appgw-public-frontend"
    frontend_port_name = "frontend-port-80"
    protocol = "Http"
  }

  request_routing_rule {
    name = "http-routing-rule"
    rule_type = "Basic"
    http_listener_name = "http-listener"
    backend_address_pool_name = "vmss-backend-pool"
    backend_http_settings_name = "backend-http-settings"
    priority = 100
  }

  tags = local.common_tags
}

# -------------------------------------
# VM Scale Set
# -------------------------------------

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name = "vmss-${local.name_prefix}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku = var.vmss_sku
  instances = var.vmss_initial_instane_count
  zones = ["1", "2", "3"]

  admin_username = var.admin_username
  disable_password_authentication = true

  upgrade_mode = "Automatic"

  admin_ssh_key {
    username = var.admin_username
    public_key = var.ssh_public_key
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "0001-com-ubuntu-server-jammy"
    sku = "22_04-lts"
    version = "latest"
  }

  os_disk {
    storage_account_type = "StandardSSD_LRS"
    caching = "ReadWrite"
  }

  network_interface {
    name = "nic-vmss"
    primary = true

    ip_configuration {
      name = "ipconfig-vmss"
      primary = true
      subnet_id = azurerm_subnet.vmss_subnet.id

      application_gateway_backend_address_pool_ids = [
        one(azurerm_application_gateway.appgw.backend_address_pool).id
      ]
    }
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    
    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title> Azure Resume Project</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                background: #f4f7fb;
                margin: 0;
                padding: 40px;
                color: #222;
            }
            .card {
                background: white;
                padding: 32px;
                border-radius: 12px;
                max-width: 800px;
                margin: 800px;
                box-shadow: 0 8px 30px rgba(0,0,0,0.08);
            }
            h1 {
                color: #0078d4
            }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>${var.resume_name}</h1>
                <h2>Azure Cloud Engineering Portfolio</h2>
                <p>This resume website is running on an Azure Virtual Machine Scale Set behind an Application Gateway WAF. </p>
                <p>The infrastructure was deployed using Terraform.</p>
                <p>Backend instances are private and reachable administratively through Azure Bastion</p>
            </div>
        </body>
    </html>
HTML

        systemctl enable nginx
        systemctl restart nginx
    EOF
    )

    tags = local.common_tags

    depends_on = [
        azurerm_application_gateway.appgw
    ]
}

# -------------------------------------
# Autoscale Rule for VMSS
# -------------------------------------

resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name = "autoscale-vmss-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  target_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
  enabled = true

  profile {
    name = "cpu-autoscale-profile"

    capacity {
      default = var.vmss_initial_instane_count
      minimum = var.vmss_min_instance_count
      maximum = var.vmss_max_instance_count
    }

    rule {
      metric_trigger {
        metric_name = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
        time_grain = "PT1M"
        statistic = "Average"
        time_window = "PT5M"
        time_aggregation = "Average"
        operator = "GreaterThan"
        threshold = 70
      }

      scale_action {
        direction = "Increase"
        type = "ChangeCount"
        value = "1"
        cooldown = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
        time_grain = "PT1M"
        statistic = "Average"
        time_window = "PT10M"
        time_aggregation = "Average"
        operator = "LessThan"
        threshold = 40
      }

      scale_action {
        direction = "Decrease"
        type = "ChangeCount"
        value = "1"
        cooldown = "PT10M"
      }
    }
  }

  tags = local.common_tags
}

# -------------------------------------
# Bastion Host
# -------------------------------------

resource "azurerm_public_ip" "bastion_pip" {
  name = "pip-bastion-${local.name_prefix}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Static"
  sku = "Standard"

  tags = local.common_tags
}

resource "azurerm_bastion_host" "bastion" {
  name = "bastion-${local.name_prefix}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "bastion-ip-config"
    subnet_id = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = local.common_tags
}

# -------------------------------------
# Key Vault
# -------------------------------------

resource "azurerm_key_vault" "kv" {
  name = "keyvault${random_integer.suffix.result}${var.environment}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"
  enable_rbac_authorization = true
  purge_protection_enabled = false 

  tags = local.common_tags
}

resource "azurerm_role_assignment" "current_user_kv_admin" {
  scope = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "vmss_kv_secrets_user" {
  scope = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id = azurerm_linux_virtual_machine_scale_set.vmss.identity[0].principal_id
}

resource "random_password" "sql_admin_password" {
  length = 24
  special = true
  override_special = "!#$%&*()-_=+{}[]<>:?"
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name = "sql-admin-password"
  value = random_password.sql_admin_password.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [ 
    azurerm_role_assignment.current_user_kv_admin
   ]
}

# -------------------------------------
# Azure SQL Database with Private Endpoint 
# -------------------------------------

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

# -------------------------------------
# Storage Account for Static Content
# -------------------------------------

resource "azurerm_storage_account" "static" {
  name = "stacc${random_integer.suffix.result}${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = "Standard"
  account_replication_type = "ZRS"

  min_tls_version = "TLS1_2"
  allow_nested_items_to_be_public = true

  static_website {
    index_document = "index.html"
  }

  tags = local.common_tags
}

# -------------------------------------
# Action Group and Alert 
# -------------------------------------

resource "azurerm_monitor_action_group" "main" {
  name = "ag_alerts-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  short_name = "alerts"

  email_receiver {
    name = "Primary-Admin-Email"
    email_address = var.alert_email
  }

  tags = local.common_tags
}

resource "azurerm_monitor_metric_alert" "high_cpu_vmss" {
  name = "alert-high-cpu-vmss-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  scopes = [azurerm_linux_virtual_machine_scale_set.vmss.id]
  description = "Alert when average VMSS CPU is greater than 70%"
  severity = 2
  frequency = "PT1M"
  window_size = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name = "Percentage CPU"
    aggregation = "Average"
    operator = "GreaterThan"
    threshold = 70
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}
