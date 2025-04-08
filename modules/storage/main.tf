# modules/storage/main.tf

# Create Resource Group for Storage
resource "azurerm_resource_group" "storage_rg" {
  name     = "${var.prefix}-${var.environment}-storage-rg"
  location = var.location
  tags     = var.tags
}

# Create Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = "${var.prefix}${var.environment}sa"
  resource_group_name      = azurerm_resource_group.storage_rg.name
  location                 = azurerm_resource_group.storage_rg.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = "StorageV2"
  
  # S2C2F Level 3 Security Requirements
  min_tls_version              = "TLS1_2"

  public_network_access_enabled = var.environment == "prod" ? false : true
  shared_access_key_enabled    = true
  
  # Blob-specific settings
  is_hns_enabled               = false
  nfsv3_enabled                = false
  
  # Encryption settings
  customer_managed_key {
    key_vault_key_id          = var.key_vault_key_id
    user_assigned_identity_id = var.user_assigned_identity_id
  }
  
  # Network rules - deny public access by default for Prod
  network_rules {
    default_action             = var.environment == "prod" ? "Deny" : "Allow"
    ip_rules                   = var.allowed_ip_addresses
    virtual_network_subnet_ids = [var.aks_subnet_id]
    bypass                     = ["AzureServices"]
  }
  
  # Lifecycle settings for S2C2F compliance
  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    
    # Retention policies
    delete_retention_policy {
      days = var.blob_soft_delete_retention_days
    }
    
    container_delete_retention_policy {
      days = var.container_soft_delete_retention_days
    }
  }
  
  # Identity for Key Vault access
  identity {
    type = "UserAssigned"
    identity_ids = [
      var.user_assigned_identity_id
    ]
  }
  
  tags = var.tags
}

# Create Private Endpoint for Storage
resource "azurerm_private_endpoint" "storage_pe" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "${var.prefix}-${var.environment}-storage-pe"
  location            = azurerm_resource_group.storage_rg.location
  resource_group_name = azurerm_resource_group.storage_rg.name
  subnet_id           = var.aks_subnet_id

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-storage-psc"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
  
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }
}

# Create Private DNS Zone for Storage
resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.storage_rg.name
  tags                = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "storage_dns_link" {
  name                  = "${var.prefix}-${var.environment}-storage-dns-link"
  resource_group_name   = azurerm_resource_group.storage_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

# Create Blob Containers for Harbor
resource "azurerm_storage_container" "harbor_registry" {
  name                  = "registry"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "harbor_chartmuseum" {
  name                  = "chartmuseum"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "harbor_trivy" {
  name                  = "trivy"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

# Create diagnostic settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage_diag" {
  name                       = "${var.prefix}-${var.environment}-storage-diag"
  target_resource_id         = azurerm_storage_account.storage.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 30
    }
  }
}

# Create diagnostic settings for blob storage specifically
resource "azurerm_monitor_diagnostic_setting" "storage_blob_diag" {
  name                       = "${var.prefix}-${var.environment}-blob-diag"
  target_resource_id         = "${azurerm_storage_account.storage.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "StorageRead"
  }
  
  enabled_log {
    category = "StorageWrite"
  }
  
  enabled_log {
    category = "StorageDelete"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
    
    retention_policy {
      enabled = true
      days    = 30
    }
  }
}

# Store Storage Account keys in Key Vault
resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "${var.prefix}-${var.environment}-storage-connection"
  value        = azurerm_storage_account.storage.primary_connection_string
  key_vault_id = var.key_vault_id
  
  # Set expiration date for secrets
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now
  
  # Apply tags
  tags = merge(var.tags, {
    secret_type = "connection-string"
    application = "harbor"
  })
}

resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "${var.prefix}-${var.environment}-storage-key"
  value        = azurerm_storage_account.storage.primary_access_key
  key_vault_id = var.key_vault_id
  
  # Set expiration date for secrets
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now
  
  # Apply tags
  tags = merge(var.tags, {
    secret_type = "access-key"
    application = "harbor"
  })
}