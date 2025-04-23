# modules/acr/main.tf

# Create Resource Group for ACR
resource "azurerm_resource_group" "acr_rg" {
  name     = "${var.prefix}-${var.environment}-acr-rg"
  location = var.location
  tags     = var.tags
}

# Create Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "${var.prefix}${var.environment}acr"
  resource_group_name = azurerm_resource_group.acr_rg.name
  location            = azurerm_resource_group.acr_rg.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  
  # S2C2F Level 3 compliance settings
  public_network_access_enabled = var.environment == "prod" ? false : true
  
  # Enable image vulnerability scanning
  dynamic "georeplications" {
    for_each = var.geo_replications
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
      tags                    = georeplications.value.tags
    }
  }
  
  # Enable image quarantine for S2C2F Level 3 compliance in production
  quarantine_policy_enabled = var.environment == "prod" ? true : false
  
  # Enable network rules
  network_rule_set {
    default_action = var.network_default_action
    
    dynamic "ip_rule" {
      for_each = var.allowed_ip_ranges
      content {
        action   = "Allow"
        ip_range = ip_rule.value
      }
    }
    
    dynamic "virtual_network" {
      for_each = var.allowed_subnet_ids
      content {
        action    = "Allow"
        subnet_id = virtual_network.value
      }
    }
  }
  
  # Enable encryption with customer managed key for production
  dynamic "encryption" {
    for_each = var.key_vault_key_id != null ? [1] : []
    content {
      key_vault_key_id   = var.key_vault_key_id
      identity_client_id = var.user_assigned_identity_id
    }
  }
  
  # Identity for Key Vault access if using CMK
  dynamic "identity" {
    for_each = var.user_assigned_identity_id != null ? [1] : []
    content {
      type = "UserAssigned"
      identity_ids = [
        var.user_assigned_identity_id
      ]
    }
  }
  
  tags = var.tags
}

# Create Private Endpoint for ACR (production only)
resource "azurerm_private_endpoint" "acr_pe" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "${var.prefix}-${var.environment}-acr-pe"
  location            = azurerm_resource_group.acr_rg.location
  resource_group_name = azurerm_resource_group.acr_rg.name
  subnet_id           = var.aks_subnet_id

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr[0].id]
  }
}

# Create Private DNS Zone for ACR (production only)
resource "azurerm_private_dns_zone" "acr" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.acr_rg.name
  tags                = var.tags
}

# Link Private DNS Zone to VNet (production only)
resource "azurerm_private_dns_zone_virtual_network_link" "acr_dns_link" {
  count                 = var.environment == "prod" ? 1 : 0
  name                  = "${var.prefix}-${var.environment}-acr-dns-link"
  resource_group_name   = azurerm_resource_group.acr_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

# Store ACR credentials in Key Vault
resource "azurerm_key_vault_secret" "acr_admin_username" {
  count        = var.admin_enabled ? 1 : 0
  name         = "${var.prefix}-${var.environment}-acr-admin-username"
  value        = azurerm_container_registry.acr.admin_username
  key_vault_id = var.key_vault_id
  
  # Set expiration date for secrets
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now
  
  # Apply tags
  tags = merge(var.tags, {
    secret_type = "credential"
    application = "harbor"
  })
}

resource "azurerm_key_vault_secret" "acr_admin_password" {
  count        = var.admin_enabled ? 1 : 0
  name         = "${var.prefix}-${var.environment}-acr-admin-password"
  value        = azurerm_container_registry.acr.admin_password
  key_vault_id = var.key_vault_id
  
  # Set expiration date for secrets
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now
  
  # Apply tags
  tags = merge(var.tags, {
    secret_type = "credential"
    application = "harbor"
  })
}

# Set up diagnostic settings for ACR
resource "azurerm_monitor_diagnostic_setting" "acr_diag" {
  name                       = "${var.prefix}-${var.environment}-acr-diag"
  target_resource_id         = azurerm_container_registry.acr.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  # Collect all ACR logs
  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
    
    retention_policy {
      enabled = true
      days    = 30
    }
  }
  
  enabled_log {
    category = "ContainerRegistryLoginEvents"
    
    retention_policy {
      enabled = true
      days    = 30
    }
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

# Create replicated Container Registry in secondary region for production
resource "azurerm_container_registry_scope_map" "harbor_scope" {
  name                    = "${var.prefix}-${var.environment}-harbor-scope"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = azurerm_resource_group.acr_rg.name
  
  actions = [
    "repositories/*/metadata/read",
    "repositories/*/metadata/write",
    "repositories/*/content/read",
    "repositories/*/content/write"
  ]
}

# Create ACR token for Harbor (for backup/replication purposes)
resource "azurerm_container_registry_token" "harbor_token" {
  name                    = "${var.prefix}-${var.environment}-harbor-token"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = azurerm_resource_group.acr_rg.name
  scope_map_id            = azurerm_container_registry_scope_map.harbor_scope.id
  
  # Store token password in Key Vault
  provisioner "local-exec" {
    command = <<EOT
      TOKEN_PWD=$(az acr token credential generate --registry ${azurerm_container_registry.acr.name} --name ${var.prefix}-${var.environment}-harbor-token --query passwords[0].value -o tsv)
      az keyvault secret set --vault-name ${element(split("/", var.key_vault_id), length(split("/", var.key_vault_id)) - 1)} --name ${var.prefix}-${var.environment}-acr-harbor-token --value $TOKEN_PWD
    EOT
  }
}