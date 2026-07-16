variable "project_name" {
  description = "Name of the project."
  type        = string
  default     = "vmss-project"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dr"
}

variable "owner" {
  description = "Owner tag value."
  type        = string
  default     = "Richard"
}

variable "location" {
  description = "Azure region. West US is the Azure-paired DR region for East US."
  type        = string
  default     = "westus"
}

# -------------------------------------
# Networking
# -------------------------------------

variable "address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "appgw_subnet_prefix" {
  description = "Address prefix for the Application Gateway subnet."
  type        = list(string)
  default     = ["10.10.1.0/24"]
}

variable "web_subnet_prefix" {
  description = "Address prefix for the web tier VMSS subnet."
  type        = list(string)
  default     = ["10.10.2.0/24"]
}

variable "app_subnet_prefix" {
  description = "Address prefix for the app tier VMSS subnet."
  type        = list(string)
  default     = ["10.10.3.0/24"]
}

variable "private_endpoint_subnet_prefix" {
  description = "Address prefix for the private endpoint subnet."
  type        = list(string)
  default     = ["10.10.4.0/24"]
}

variable "bastion_subnet_prefix" {
  description = "Address prefix for the AzureBastionSubnet. Must be /26 or larger."
  type        = list(string)
  default     = ["10.10.5.0/26"]
}

# -------------------------------------
# Availability
# -------------------------------------
# West US does not have Availability Zones, so zonal resources (VMSS,
# Application Gateway PIP, internal LB) must deploy without zones here.

variable "availability_zones" {
  description = "Availability zones used by zonal resources. Empty because West US has no Availability Zone support."
  type        = list(string)
  default     = []
}

# -------------------------------------
# Application Gateway
# -------------------------------------

variable "waf_mode" {
  description = "WAF policy mode: Detection or Prevention."
  type        = string
  default     = "Prevention"
}

variable "appgw_min_capacity" {
  description = "Minimum Application Gateway v2 instance count."
  type        = number
  default     = 1
}

variable "appgw_max_capacity" {
  description = "Maximum Application Gateway v2 instance count."
  type        = number
  default     = 3
}

# -------------------------------------
# Compute
# -------------------------------------

variable "admin_username" {
  description = "Azure admin username for VMSS instances."
  type        = string
  default     = "richieazureadmin"
}

variable "ssh_public_key" {
  description = "SSH public key used to access the VMSS instances through Azure Bastion."
  type        = string
  sensitive   = true
}

variable "resume_name" {
  description = "Name displayed on the resume landing page."
  type        = string
  default     = "Richard Alvarez"
}

variable "vmss_sku" {
  description = "VM size for the VMSS instances."
  type        = string
  default     = "Standard_B1s"
}

variable "web_initial_instance_count" {
  description = "Initial number of web tier VMSS instances."
  type        = number
  default     = 1
}

variable "web_min_instance_count" {
  description = "Minimum number of web tier VMSS instances."
  type        = number
  default     = 1
}

variable "web_max_instance_count" {
  description = "Maximum number of web tier VMSS instances."
  type        = number
  default     = 3
}

variable "app_initial_instance_count" {
  description = "Initial number of app tier VMSS instances."
  type        = number
  default     = 1
}

variable "app_min_instance_count" {
  description = "Minimum number of app tier VMSS instances."
  type        = number
  default     = 1
}

variable "app_max_instance_count" {
  description = "Maximum number of app tier VMSS instances."
  type        = number
  default     = 3
}

# -------------------------------------
# Database
# -------------------------------------

variable "sql_admin_username" {
  description = "SQL Admin Username."
  type        = string
  default     = "richiesqladmin"
}

variable "sql_database_sku" {
  description = "Azure SQL Database SKU."
  type        = string
  default     = "GP_Gen5_2"
}

variable "sql_zone_redundant" {
  description = "Whether Azure SQL Database should use zone redundancy. False here because West US has no Availability Zone support."
  type        = bool
  default     = false
}

# -------------------------------------
# Key Vault
# -------------------------------------

variable "kv_purge_protection_enabled" {
  description = "Whether purge protection is enabled on the Key Vault."
  type        = bool
  default     = true
}

# -------------------------------------
# Monitoring
# -------------------------------------

variable "alert_email" {
  description = "Email address for Azure Monitor action group alerts."
  type        = string
}