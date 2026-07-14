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
      default = var.vmss_initial_instance_count
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
}