variable "name_prefix" {
  description = "Naming prefix applied to all app tier resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group in which to create the app tier VMSS."
  type        = string
}

variable "location" {
  description = "Azure region for the app tier VMSS."
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "subnet_id" {
  description = "ID of the app tier subnet."
  type        = string
}

variable "internal_lb_backend_address_pool_id" {
  description = "ID of the internal load balancer backend address pool to attach the app tier VMSS to."
  type        = string
}

variable "admin_username" {
  description = "Admin username for the app tier VMSS instances."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key used to access the app tier VMSS instances."
  type        = string
  sensitive   = true
}

variable "vmss_sku" {
  description = "VM size for the app tier VMSS instances."
  type        = string
  default     = "Standard_B1s"
}

variable "instance_count" {
  description = "Initial number of app tier VMSS instances."
  type        = number
  default     = 2
}

variable "availability_zones" {
  description = "Availability zones for the app tier VMSS. Pass an empty list in regions without Availability Zone support (e.g. West US)."
  type        = list(string)
  default     = ["1", "2", "3"]
}