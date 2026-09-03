variable "name_prefix" {
  description = "Naming prefix applied to all Application Gateway resources."
  type = string
}

variable "resource_group_name" {
  description = "Resource group in which we will create the Application Gateway."
  type = string
}

variable "location" {
  description = "Azure region for the Application Gateway."
  type = string
}

variable "tags" {
  description = "Common tags applied to all resources."
  type = map(string)
  default = {}
}

variable "subnet_id" {
  description = "ID of the subnet where the Application Gateway will be deployed."
  type = string
}

variable "waf_mode" {
  description = "WAF policy mode: Detection or Prevention."
  type = string
}

variable "min_capacity" {
  description = "Minimum Application Gateway v2 instance count."
  type = number
  default = 1 
}

variable "max_capacity" {
  description = "Maximum Application Gateway v2 instance count."
  type = number
  default = 2
}

variable "availability_zones" {
  description = "Availability zones for the Application Gateway's public IP. Pass an empty list in regions without Availability Zone support (like West US)."
  type = list(string)
  default = ["1", "2", "3"]
}