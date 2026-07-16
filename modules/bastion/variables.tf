variable "name_prefix" {
  description = "Naming prefix applied to all Bastion resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group in which to create the Bastion host."
  type        = string
}

variable "location" {
  description = "Azure region for the Bastion host."
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "subnet_id" {
  description = "ID of the AzureBastionSubnet."
  type        = string
}