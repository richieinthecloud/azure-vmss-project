terraform {
  required_version = ">=1.6.0"
  # terraform core version

  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4.0"
        # azurerm provider version
    }

    random = {
        source = "hashicorp/random"
        version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}