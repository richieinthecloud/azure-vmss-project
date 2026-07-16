variable "name_prefix" {
  description = "Naming prefix used for the random component of the Key Vault name."
  type        = string
}

variable "environment" {
  description = "Environment name, appended to the Key Vault name for global uniqueness."
  type        = string
}

variable "random_suffix" {
  description = "Random numeric suffix, appended to the Key Vault name for global uniqueness."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group in which to create the Key Vault."
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault."
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "tenant_id" {
  description = "Azure AD tenant ID for the Key Vault."
  type        = string
}

variable "deployer_object_id" {
  description = "Object ID of the principal running Terraform, granted Key Vault Administrator."
  type        = string
}

variable "app_tier_principal_id" {
  description = "Principal ID of the app tier VMSS managed identity, granted Key Vault Secrets User."
  type        = string
}

variable "purge_protection_enabled" {
  description = "Whether purge protection is enabled on the Key Vault."
  type        = bool
  default     = false
}