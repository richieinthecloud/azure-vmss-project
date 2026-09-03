# -------------------------------------
# Log Analytics workspace (central log/metric store)
# -------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_in_days

  tags = var.tags
}

# -------------------------------------
# Diagnostic settings: ship VMSS platform metrics to the workspace
# (VMSS scale-set resources expose metrics only; guest OS logs would
# require the Azure Monitor Agent + a data collection rule.)
# -------------------------------------

resource "azurerm_monitor_diagnostic_setting" "web_vmss" {
  name                       = "diag-web-${var.name_prefix}"
  target_resource_id         = var.web_vmss_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "app_vmss" {
  name                       = "diag-app-${var.name_prefix}"
  target_resource_id         = var.app_vmss_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_metric {
    category = "AllMetrics"
  }
}

# -------------------------------------
# Autoscale: Web tier
# -------------------------------------

resource "azurerm_monitor_autoscale_setting" "web" {
  name                = "autoscale-web-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = var.web_vmss_id
  enabled             = true

  profile {
    name = "cpu-autoscale-profile"

    capacity {
      default = var.web_initial_instance_count
      minimum = var.web_min_instance_count
      maximum = var.web_max_instance_count
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.web_vmss_id
        metric_namespace   = "Microsoft.Compute/virtualMachineScaleSets"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.web_vmss_id
        metric_namespace   = "Microsoft.Compute/virtualMachineScaleSets"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 40
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }
  }

  tags = var.tags
}

# -------------------------------------
# Autoscale: App tier
# -------------------------------------

resource "azurerm_monitor_autoscale_setting" "app" {
  name                = "autoscale-app-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = var.app_vmss_id
  enabled             = true

  profile {
    name = "cpu-autoscale-profile"

    capacity {
      default = var.app_initial_instance_count
      minimum = var.app_min_instance_count
      maximum = var.app_max_instance_count
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.app_vmss_id
        metric_namespace   = "Microsoft.Compute/virtualMachineScaleSets"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.app_vmss_id
        metric_namespace   = "Microsoft.Compute/virtualMachineScaleSets"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 40
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }
  }

  tags = var.tags
}

# -------------------------------------
# Action Group and Alerts
# -------------------------------------

resource "azurerm_monitor_action_group" "main" {
  name                = "ag-alerts-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  short_name          = "alerts"

  email_receiver {
    name          = "Primary-Admin-Email"
    email_address = var.alert_email
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "high_cpu_web" {
  name                = "alert-high-cpu-web-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.web_vmss_id]
  description         = "Alert when average web tier VMSS CPU is greater than 70%"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 70
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# VM availability drops below 100% (an instance became unavailable)
resource "azurerm_monitor_metric_alert" "availability_web" {
  name                = "alert-availability-web-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.web_vmss_id]
  description         = "Alert when web tier VMSS VM availability drops below 100%"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# Azure-reported resource health degrades (platform-level availability signal)
resource "azurerm_monitor_activity_log_alert" "health_web" {
  name                = "alert-health-web-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = [var.web_vmss_id]
  description         = "Alert when Azure reports the web tier VMSS as degraded or unavailable"

  criteria {
    category = "ResourceHealth"

    resource_health {
      current  = ["Degraded", "Unavailable"]
      previous = ["Available"]
      reason   = ["PlatformInitiated", "UserInitiated", "Unknown"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "high_cpu_app" {
  name                = "alert-high-cpu-app-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.app_vmss_id]
  description         = "Alert when average app tier VMSS CPU is greater than 70%"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 70
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# VM availability drops below 100% (an instance became unavailable)
resource "azurerm_monitor_metric_alert" "availability_app" {
  name                = "alert-availability-app-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.app_vmss_id]
  description         = "Alert when app tier VMSS VM availability drops below 100%"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# Azure-reported resource health degrades (platform-level availability signal)
resource "azurerm_monitor_activity_log_alert" "health_app" {
  name                = "alert-health-app-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = "global"
  scopes              = [var.app_vmss_id]
  description         = "Alert when Azure reports the app tier VMSS as degraded or unavailable"

  criteria {
    category = "ResourceHealth"

    resource_health {
      current  = ["Degraded", "Unavailable"]
      previous = ["Available"]
      reason   = ["PlatformInitiated", "UserInitiated", "Unknown"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# Guest OS Log Collection: Azure Monitor Agent + Data Collection Rule
# Diagnostic settings on a VMSS give platform metrics only.
# To see what's happening inside the instances (cloud-init, sshd, nginx, kernel) the agent
# must run in the guest and ship syslog to the workspace under a DCR. 

resource "azurerm_monitor_data_collection_rule" "vmss_syslog" {
  name                = "dcr-syslog-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "Linux"

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
      name                  = "law"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["law"]
  }

  data_sources {
    syslog {
      name           = "syslog"
      streams        = ["Microsoft-Syslog"]
      facility_names = ["auth", "authpriv", "cron", "daemon", "kern", "syslog", "user", "local7"]
      log_levels     = ["Info", "Notice", "Warning", "Error", "Critical", "Alert", "Emergency"]
    }
  }
  tags = var.tags
}

# the agent extension. In automatic upgrade mode, adding this triggers a rolling update
# of existing instances; new instances get it at creation. 

resource "azurerm_virtual_machine_scale_set_extension" "ama_web" {
  name                         = "AzureMonitorLinuxAgent"
  virtual_machine_scale_set_id = var.web_vmss_id
  publisher                    = "Microsoft.Azure.Monitor"
  type                         = "AzureMonitorLinuxAgent"
  type_handler_version         = "1.0"
  auto_upgrade_minor_version   = true
  automatic_upgrade_enabled    = true
}

resource "azurerm_virtual_machine_scale_set_extension" "ama_app" {
  name                         = "AzureMonitorLinuxAgent"
  virtual_machine_scale_set_id = var.app_vmss_id
  publisher                    = "Microsoft.Azure.Monitor"
  type                         = "AzureMonitorLinuxAgent"
  type_handler_version         = "1.0"
  auto_upgrade_minor_version   = true
  automatic_upgrade_enabled    = true
}

# bind the rule to each scale set.
# without the association the agent runs but collects nothing. 
resource "azurerm_monitor_data_collection_rule_association" "web" {
  name                    = "dcra-web-${var.name_prefix}"
  target_resource_id      = var.web_vmss_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vmss_syslog.id
}

resource "azurerm_monitor_data_collection_rule_association" "app" {
  name                    = "dcra-app-${var.name_prefix}"
  target_resource_id      = var.app_vmss_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vmss_syslog.id
}


# Application Gateway logs: access, performance, and WAF.
# "Dedicated" writes to resource-specific tables 
# (AGWAccessLogs,AGWFirewallLogs, AGWPerformanceLogs) rather than the catch-all
# AzureDiagnostics table — much easier to query.

resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                           = "diag-appgw-${var.name_prefix}"
  target_resource_id             = var.app_gateway_id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.main.id
  log_analytics_destination_type = "Dedicated"

  enabled_log { category = "ApplicationGatewayAccessLog" }
  enabled_log { category = "ApplicationGatewayPerformanceLog" }
  enabled_log { category = "ApplicationGatewayFirewallLog" }

  enabled_metric { category = "AllMetrics" }
}

resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "diag-kv-${var.name_prefix}"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log { category = "AuditEvent" }
  enabled_metric { category = "AllMetrics" }
}
