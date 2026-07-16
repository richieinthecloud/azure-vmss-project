resource "random_integer" "suffix" {
  min = 10000
  max = 99999
  # this is so I don't have to worry about giving my resource globally unique names
  # the Azure Resource Manager will instead do it for me
}

locals {
  name_prefix = "${var.project_name}-${var.environment}-${random_integer.suffix.result}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}