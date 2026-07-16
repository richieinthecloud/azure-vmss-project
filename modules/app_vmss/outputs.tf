output "vmss_id" {
  description = "ID of the app tier VMSS."
  value       = azurerm_linux_virtual_machine_scale_set.app.id
}

output "vmss_name" {
  description = "Name of the app tier VMSS."
  value       = azurerm_linux_virtual_machine_scale_set.app.name
}

output "principal_id" {
  description = "Principal ID of the app tier VMSS's system-assigned managed identity."
  value       = azurerm_linux_virtual_machine_scale_set.app.identity[0].principal_id
}