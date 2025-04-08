# modules/key_vault/main.tf

# Create Resource Group for Key Vault
resource "azurerm_resource_group" "kv_rg" {
  name     = "${var.prefix}-${var.environment}-kv-rg"
  location = var.location
  tags     = var.tags
}

# Create Key Vault
resource "azurerm_key_vault" "vault" {
  name                       = "${var.prefix}-${var.environment}-kv"
  location                   = azurerm_resource_group.kv_rg.location
  resource_group_name        = azurerm_resource_group.kv_rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  sku_name                   = "standard"
  
  # Enable RBAC for Key Vault
  enabled_for_deployment  = true
  
  # Configure network access based on environment
  network_acls {
    default_action = var.environment == "prod" ? "Deny" : "Allow"
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }
  
  tags = var.tags
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Assign Key Vault Administrator role to the current user/service principal
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Assign Key Vault Reader role to the AKS identity
resource "azurerm_role_assignment" "kv_reader_aks" {
  count                = var.aks_identity_principal_id != null ? 1 : 0
  scope                = azurerm_key_vault.vault.id
  role_definition_name = "Key Vault Reader"
  principal_id         = var.aks_identity_principal_id
}

# Assign Key Vault Secrets User role to the AKS identity
resource "azurerm_role_assignment" "kv_secrets_user_aks" {
  count                = var.aks_identity_principal_id != null ? 1 : 0
  scope                = azurerm_key_vault.vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.aks_identity_principal_id
}

# Create Key Vault secrets for Harbor
resource "azurerm_key_vault_secret" "harbor_admin_password" {
  name         = "harbor-admin-password"
  value        = var.harbor_admin_password
  key_vault_id = azurerm_key_vault.vault.id
  
  # Set expiration date for secrets
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now
  
  # Apply tags
  tags = merge(var.tags, {
    secret_type = "credential"
    application = "harbor"
  })
}

resource "azurerm_key_vault_secret" "harbor_db_password" {
  name         = "harbor-db-password"
  value        = var.harbor_db_password
  key_vault_id = azurerm_key_vault.vault.id
  
  # Set expiration date for secrets
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now
  
  # Apply tags
  tags = merge(var.tags, {
    secret_type = "credential"
    application = "harbor"
  })
}

resource "azurerm_key_vault_secret" "harbor_redis_password" {
  name         = "harbor-redis-password"
  value        = var.harbor_redis_password
  key_vault_id = azurerm_key_vault.vault.id
  
  # Set expiration date for secrets
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now
  
  # Apply tags
  tags = merge(var.tags, {
    secret_type = "credential"
    application = "harbor"
  })
}

# Store TLS certificates
resource "azurerm_key_vault_certificate" "harbor_tls" {
  count        = var.harbor_tls_cert != null && var.harbor_tls_key != null ? 1 : 0
  name         = "harbor-tls-cert"
  key_vault_id = azurerm_key_vault.vault.id

  certificate {
    contents = var.harbor_tls_cert
    password = ""
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
  
  # Apply tags
  tags = merge(var.tags, {
    secret_type = "certificate"
    application = "harbor"
  })
}

# Create diagnostic settings for key vault
resource "azurerm_monitor_diagnostic_setting" "kv_diag" {
  name                       = "${var.prefix}-${var.environment}-kv-diag"
  target_resource_id         = azurerm_key_vault.vault.id
  log_analytics_workspace_id = var.log_analytics_workspace_id


  metric {
    category = "AllMetrics"
    enabled  = true
  }
}