output "action_group_id" {
  description = "ID of the shared Azure Monitor action group."
  value       = azurerm_monitor_action_group.main.id
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace collecting VMSS diagnostics."
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace collecting VMSS diagnostics."
  value       = azurerm_log_analytics_workspace.main.name
}