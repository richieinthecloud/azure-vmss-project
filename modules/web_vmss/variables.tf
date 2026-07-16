variable "name_prefix" {
  description = "Naming prefix applied to all web tier resources."
  type = string
}

variable "resource_group_name" {
  description = "Resource group in which to create the web tier VMSS."
  type = string
}

variable "location" {
  description = "Azure region for the web tier VMSS."
  type = string
}

variable "tags" {
  description = "Common tags applied to all resources."
  type = map(string)
  default = {}
}

variable "subnet_id" {
  description = "ID of the web tier subnet."
  type = string
}

variable "appgw_backend_address_pool_id" {
  description = "ID of the Application Gateway backend address pool to attach the web tier VMSS to."
  type = string
}

variable "internal_lb_frontend_ip" {
  description = "Private IP address of the internal load balancer fronting the app tier, used for the web tier's reverse proxy to the app tier."
  type = string
}

variable "admin_username" {
  description = "Admin username for the web tier VMSS instances"
  type = string
}

variable "ssh_public_key" {
  description = "SSH public key used to access the web tier VMSS instances."
  type = string
  sensitive = true
}

variable "vmss_sku" {
  description = "VM size for the web tier VMSS instances."
  type = string
  default = "Standard_B1s"
}

variable "instance_count" {
  description = "Initial number of web tier VMSS instances."
  type = number
  default = 1
}

variable "resume_name" {
  description = "Name displayed on the resume landing page."
  type = string
}

variable "availability_zones" {
  description = "Availability zones for the web tier VMSS. Pass an empty list in regions without Availability Zone support (Like West US)."
  type = list(string)
  default = [ "1", "2", "3" ]
}