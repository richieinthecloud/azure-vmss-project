# The areas commented out is how one would simulate keeping 
# storage details secret in a corporate/professional environment
#
# Remote state backend (Azure Storage). Values are intentionally left out
# of source control (partial configuration) - supply them at `terraform init`
# time so the same backend.tf works across machines/CI without leaking the
# storage account name into the repo.
#
# terraform init \
#   -backend-config="resource_group_name=<state-rg>" \
#   -backend-config="storage_account_name=<state-storage-account>" \
#   -backend-config="container_name=tfstate" \
#   -backend-config="key=vmss-project/dev.terraform.tfstate"
#
# Or point -backend-config at a gitignored backend.hcl file per environment.

terraform {
  backend "azurerm" {
    resource_group_name = "tfstate-remotebackend"
    storage_account_name = "vmssdemobackendrichie"
    container_name = "tfstate"
    key = "dev.terraform.tfstate"
  }
}