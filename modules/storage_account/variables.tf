variable "location" {
  description = "Azure region for the Terraform remote state storage account."
  type = string
  default = "eastus"
}

variable "resource_group_name" {
  description = "Resource group dedicated to Terraform remote state."
  type = string
  default = "rg-tfstate-vmss-demo"
}

variable "storage_account_name" {
  description = "Name for the state storage account."
  type = string
  default = "tfstatevmssdemorichie"
}

variable "container_name" {
  description = "Blob container that holds the .tfstate files for dev, prod and dr."
  type = string
  default = "tfstate"
}

variable "ci_principal_id" {
  description = "Object ID of the service principal / app registration Github actions uses to log in via OIDC."
  # null until that app registration exists, then re-apply to grant it access. 
  type = string
  default = null
}

variable "tags" {
  description = "Common tags applied to the state storage resources."
  type = map(string)
  default = {
    "Project" = "vmss-demo"
    "Purpose" = "terraform-remote-state"
    "ManagedBy" = "Terraform"
  }
}