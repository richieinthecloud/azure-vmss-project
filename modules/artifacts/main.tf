# Why does this exist?:
# Allows for version control
# Enables rollback of artifacts
# Instances are never patched in place, they are replaced. That's what makes it immutable infrastructure

# THE PATTERN (immutable infrastructure):
#   1. scripts/build-and-publish.sh tars the app and uploads it here as
#      jobtracker-v1.2.0.tar.gz
#   2. Terraform variable app_version = "v1.2.0" is baked into the app tier's
#      cloud-init.
#   3. Each instance downloads exactly that version at boot.
#   4. To deploy: bump app_version, terraform apply. Because the VMSS is
#      upgrade_mode = "Automatic", changing custom_data triggers a ROLLING
#      UPGRADE — Azure replaces instances in batches, so there's no downtime.
#   5. To roll back: set app_version back to the previous value and apply.

resource "azurerm_storage_account" "artifacts" {
    # name must be globally unique, must be 3-24 characters long. lowercase letters and digits only
    name = "stacc${var.random_suffix}${var.environment}"
    resource_group_name = var.resource_group_name
    location = var.location

    account_tier = "Standard"
    account_replication_type = "ZRS" # zonal redundancy to survive single zone failure(s)

    # disable the two static account keys entirely. These are effectively root on the storage account, they never expire
    # These are the most commonly leaked credentials in Azure. Setting these to false means we can only auth with Entra ID
    # which means, we only have our managed identity, with a scoped RBAC role. No secret to leak
    shared_access_key_enabled = false 

    # blobs should never be made anonymously readable
    allow_nested_items_to_be_public = false

    https_traffic_only_enabled = true
    min_tls_version = "TLS1_2"

    tags = var.tags
}

resource "azurerm_storage_container" "artifacts" {
    name = "artifacts"
    storage_account_id = azurerm_storage_account.artifacts.id

    container_access_type = "private" # no anonymous access. Every read must be authenticated
}

# Setting RBAC roles
# Two principals, two different levels of access. 
# The thing that WRITES builds and the thing that READS builds are separate, and neither has more than it needs

resource "azurerm_role_assignment" "app_tier_blob_reader" {
    scope = azurerm_storage_account.artifacts.id
    role_definition_name = "Storage Blob Data Reader"
    principal_id = var.app_tier_principal_id
}

resource "azurerm_role_assignment" "deployer_blob_contributor" {
    scope = azurerm_storage_account.artifacts.id
    role_definition_name = "Storage Blob Data Contributor"
    principal_id = var.deployer_object_id
}