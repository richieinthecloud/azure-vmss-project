variable "name_prefix" {
  description = "Naming prefix applied to all intneral load balancer resources."
  type = string
}

variable "resource_group_name" {
  description = "Resource group in which we will create the internal load balancer."
  type = string
}

variable "location" {
  description = "Azure region for the internal load balancer."
  type = string
}

variable "tags" {
  description = "Common tags applied to all resources."
  type = map(string)
  default = {}
}

variable "subnet_id" {
  description = "ID of the app tier subnet the internal load balancer's frontend IP is placed in."
  type = string
}

variable "backend_port" {
    description = "Port the app tier listens on."
    type = number
    default = 80
}

variable "availability_zones" {
  description = "Availability zones for the internal load balancer's frontend IP. . Pass an empty list in regions without Availability Zone support (Like West US.)"
  type = list(string)
  default = ["1", "2", "3"]
}






