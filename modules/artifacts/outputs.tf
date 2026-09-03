output "storage_account_name" {
  description = "Name of the artifacts storage account. Used by build-and-publish.sh."
  value       = azurerm_storage_account.artifacts.name
}

output "container_name" {
  description = "Name of the blob container holding versioned app builds."
  value       = azurerm_storage_container.artifacts.name
}

output "blob_endpoint" {
  description = "Base blob endpoint (e.g. https://stapp12345dev.blob.core.windows.net/). The app tier cloud-init builds its download URL from this."
  value       = azurerm_storage_account.artifacts.primary_blob_endpoint
}