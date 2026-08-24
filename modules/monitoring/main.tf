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
#  require the Azure Monitor Agent + a data collection rule.)
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