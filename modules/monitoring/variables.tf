variable "name_prefix" {
  description = "Naming prefix applied to all monitoring resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group in which to create monitoring resources."
  type        = string
}

variable "location" {
  description = "Azure region for monitoring resources."
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "alert_email" {
  description = "Email address for Azure Monitor action group alerts."
  type        = string
}

variable "web_vmss_id" {
  description = "ID of the web tier VMSS to autoscale and alert on."
  type        = string
}

variable "web_initial_instance_count" {
  description = "Initial number of web tier VMSS instances."
  type        = number
}

variable "web_min_instance_count" {
  description = "Minimum number of web tier VMSS instances."
  type        = number
}

variable "web_max_instance_count" {
  description = "Maximum number of web tier VMSS instances."
  type        = number
}

variable "app_vmss_id" {
  description = "ID of the app tier VMSS to autoscale and alert on."
  type        = string
}

variable "app_initial_instance_count" {
  description = "Initial number of app tier VMSS instances."
  type        = number
}

variable "app_min_instance_count" {
  description = "Minimum number of app tier VMSS instances."
  type        = number
}

variable "app_max_instance_count" {
  description = "Maximum number of app tier VMSS instances."
  type        = number
}