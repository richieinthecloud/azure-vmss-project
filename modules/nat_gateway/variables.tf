variable "name_prefix" {
    description = "Naming prefix shared by all resources in this deployment."
    type = string
}

variable "resource_group_name" {
    description = "The name of the resource group in which to create the NAT gateway."
    type = string
}

variable "location" {
    description = "The Azure region in which to create the NAT gateway."
    type = string
}

variable "tags" {
    description = "Tags applied to every resource in this module."
    type = map(string)
    default = {}
}

variable "web_subnet_id" {
    description = "Web tier subnet ID that needs outbound internet access."
    type = string
}

variable "app_subnet_id" {
    description = "App tier subnet ID that needs outbound internet access."
    type = string
}