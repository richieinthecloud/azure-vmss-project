variable "resource_group_name" {
  description = "Resource group to create the storage account in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "environment" {
  description = "Environment name (dev/prod/dr). Part of the globally unique storage account name."
  type        = string
}

variable "random_suffix" {
  description = "Random integer suffix that makes the storage account name globally unique. Reuses the same random_integer.suffix as the Key Vault so all names in a deployment share one number."
  type        = number
}

variable "tags" {
  description = "Tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}

variable "app_tier_principal_id" {
  description = "Object ID of the app tier VMSS system-assigned managed identity. Granted read-only access so instances can download their build at boot."
  type        = string
}

variable "deployer_object_id" {
  description = "Object ID of the identity running Terraform (you, or the CI service principal). Granted write access so builds can be published."
  type        = string
}