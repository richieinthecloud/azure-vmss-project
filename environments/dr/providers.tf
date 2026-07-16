terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Authenticates via the Azure CLI (`az login`) or ARM_* environment variables.
# No credentials or subscription IDs are hardcoded here.
provider "azurerm" {
  features {}
}