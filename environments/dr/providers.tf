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

  # this part is important: this tells the provider to use your Entra ID identity for storage data-plane operations, 
  # instead of trying to fetch an account key. Without this, creating the artifacts container fails with a 403 error because
  # we deliberately turned account keys off
  storage_use_azuread = true
}