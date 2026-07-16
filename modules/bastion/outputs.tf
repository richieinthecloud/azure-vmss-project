output "bastion_name" {
  description = "Name of the Azure Bastion Host."
  value = azurerm_bastion_host.bastion.name
}