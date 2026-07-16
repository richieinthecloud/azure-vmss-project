variable "name_prefix" {
  description = "Naming prefix applied to all networking resources."
  type = string

}

variable "resource_group_name" {
  description = "Resource group in which we will create networking resources."
  type = string

}

variable "location" {
  description = "Azure region."
  type = string

}

variable "tags" {
  description = "Common tags applied to all resources."
  type = map(string)
  default = {}

}

variable "address_space" {
  description = "Address space for the virtual network."
  type = list(string)
  default = ["10.10.0.0/16"]

}

variable "appgw_subnet_prefix" {
  description = "Address prefix for the Application Gateway subnet."
  type = list(string)
  default = ["10.10.1.0/24"]

}

variable "webvmss_subnet_prefix" {
  description = "Address prefix for the web-tier VMSS subnet."
  type = list(string)
  default = ["10.10.2.0/24"]
}

variable "appvmss_subnet_prefix" {
  description = "Address prefix for the app-tier VMSS subnet."
  type = list(string)
  default = ["10.10.3.0/24"]
}

variable "private_endpoint_subnet_prefix" {
  description = "Address prefix for the private endpoint subnet."
  type = list(string)
  default = ["10.10.4.0/24"]
}

variable "bastion_subnet_prefix" {
  description = "Address prefix for the Azure Bastion subnet."
  type = list(string)
  default = ["10.10.5.0/26"]
}