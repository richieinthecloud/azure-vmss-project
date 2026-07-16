variable "name_prefix" {
  description = "Naming prefix applied to all database resources."
  type        = string
}

variable "environment" {
  description = "Environment name, used in the database name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group in which to create the database resources."
  type        = string
}

variable "location" {
  description = "Azure region for the database resources."
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "vnet_id" {
  description = "ID of the virtual network to link the private DNS zone to."
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "ID of the subnet the SQL private endpoint is deployed into."
  type        = string
}

variable "sql_admin_username" {
  description = "SQL Server administrator login."
  type        = string
}

variable "sql_admin_password" {
  description = "SQL Server administrator password, sourced from Key Vault."
  type        = string
  sensitive   = true
}

variable "sql_database_sku" {
  description = "Azure SQL Database SKU."
  type        = string
  default     = "GP_Gen5_2"
}

variable "sql_zone_redundant" {
  description = "Whether Azure SQL Database should use zone redundancy. Some regions/SKUs may not support this."
  type        = bool
  default     = true
}