output "action_group_id" {
  description = "ID of the shared Azure Monitor action group."
  value       = azurerm_monitor_action_group.main.id
}