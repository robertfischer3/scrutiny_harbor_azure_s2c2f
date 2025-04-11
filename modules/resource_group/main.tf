# modules/resource_group/main.tf

# Generate random suffix for storage account name to ensure uniqueness
resource "random_string" "storage_account_suffix" {
  count   = var.create_terraform_storage ? 1 : 0
  length  = 8
  special = false
  upper   = false
  numeric = true
}

# Create resource groups
resource "azurerm_resource_group" "resource_groups" {
  for_each = var.resource_groups

  name     = each.value.name
  location = each.value.location
  tags     = merge(var.tags, each.value.tags)
}

# Optionally create storage account for Terraform state
resource "azurerm_storage_account" "terraform_storage" {
  count = var.create_terraform_storage ? 1 : 0

  name                     = "${var.terraform_storage_account_prefix}${random_string.storage_account_suffix[0].result}"
  resource_group_name      = azurerm_resource_group.resource_groups["tfstate"].name
  location                 = azurerm_resource_group.resource_groups["tfstate"].location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 30
    }
    
    container_delete_retention_policy {
      days = 30
    }
  }

  tags = merge(var.tags, {
    purpose = "terraform-state"
  })
}

# Create container for Terraform state
resource "azurerm_storage_container" "terraform_container" {
  count = var.create_terraform_storage ? 1 : 0

  name                  = var.terraform_container_name
  storage_account_id    = azurerm_storage_account.terraform_storage[0].id
  container_access_type = "private"
}

# Create a role assignment to allow the current user to access the storage account
# This is useful for initial bootstrapping
resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  count = var.create_terraform_storage ? 1 : 0

  scope                = azurerm_storage_account.terraform_storage[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Get current client config
data "azurerm_client_config" "current" {}