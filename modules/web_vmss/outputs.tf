output "vmss_id" {
  description = "ID of the web tier VMSS."
  value = azurerm_linux_virtual_machine_scale_set.web-vmss.id
}

output "vmss_name" {
  description = "Name of the web tier VMSS."
  value = azurerm_linux_virtual_machine_scale_set.web-vmss.name
}

output "principal_id" {
  description = "Principal ID of the web tier VMSS's system-assigned managed identity."
  value = azurerm_linux_virtual_machine_scale_set.web-vmss.identity[0].principal_id
}