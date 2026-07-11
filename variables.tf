variable "project_name" {
  description = "Name of the project."
  type = string
  default = "vmss-project"
}

variable "environment" {
  description = "Environment name."
  type = string
  default = "dev2"
}

variable "owner" {
  description = "Owner tag value."
  type = string
  default = "Richard"
}

variable "location" {
  description = "Azure region."
  type = string
  default = "eastus2"
}

variable "admin_username" {
  description = "Azure admin username for VMSS instances."
  type = string
  default = "richieazureadmin"
}

variable "ssh_public_key" {
  description = "SSH public key used to access the VMSS instances through Azure Bastion."
  type = string
  sensitive = true
}

variable "resume_name" {
  description = "Name displayed on the resume landing page."
  type = string
  default = "Richard Alvarez"
}

variable "vmss_sku" {
  description = "VM size for the VMSS instances."
  type = string
  default = "Standard_B1s"
}

variable "vmss_initial_instane_count" {
  description = "Initial number of VMSS instances."
  type = number
  default = 2
}

variable "vmss_min_instance_count" {
  description = "Minimum number of VMSS instances."
  type = number
  default = 1
}

variable "vmss_max_instance_count" {
  description = "Maximum number of VMSS instances."
  type = number
  default = 4
}

variable "sql_admin_username" {
  description = "SQL Admin Username."
  type = string
  default = "richiesqladmin"
}

variable "sql_database_sku" {
  description = "Azure SQL Database SKU."
  type = string
  default = "GP_Gen5_2"
}

variable "sql_zone_redundant" {
  description = "Whether Azure SQL Database should use zone redundancy. Some regions/SKUs may not support this!"
  type = bool
  default = true
}

variable "alert_email" {
  description = "Email address for Azure Monitor action group alerts."
  type = string
}
