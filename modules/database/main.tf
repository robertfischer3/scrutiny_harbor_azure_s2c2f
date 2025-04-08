# modules/database/main.tf

# Create Resource Group for PostgreSQL
resource "azurerm_resource_group" "db_rg" {
  name     = "${var.prefix}-${var.environment}-db-rg"
  location = var.location
  tags     = var.tags
}

# Create PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "${var.prefix}-${var.environment}-postgres"
  resource_group_name    = azurerm_resource_group.db_rg.name
  location               = azurerm_resource_group.db_rg.location
  version                = var.postgres_version
  administrator_login    = var.postgres_admin_username
  administrator_password = var.postgres_admin_password
  storage_mb             = var.postgres_storage_mb
  sku_name               = var.postgres_sku
  zone                   = var.availability_zone
  
  # High Availability for production
  high_availability {
    mode                      = var.environment == "prod" ? "ZoneRedundant" : "Disabled"
    standby_availability_zone = var.environment == "prod" ? (var.availability_zone == "1" ? "2" : "1") : null
  }
  
  # Enable customer-managed keys for encryption
  dynamic "customer_managed_key" {
    for_each = var.key_vault_key_id != null ? [1] : []
    content {
      key_vault_key_id                     = var.key_vault_key_id
      primary_user_assigned_identity_id    = var.user_assigned_identity_id
    }
  }
  
  # Configure backup
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.environment == "prod" ? true : false
  
  # Configure maintenance window
  maintenance_window {
    day_of_week  = 0  # Sunday
    start_hour   = 2  # 2 AM
    start_minute = 0
  }
  
  # Private networking configuration
  delegated_subnet_id = var.db_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id
  
  # For S2C2F Level 3 compliance - disable public network access
  public_network_access_enabled = false
  
  tags = var.tags
  
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres_dns_link
  ]
}

# Create Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.db_rg.name
  tags                = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgres_dns_link" {
  name                  = "${var.prefix}-${var.environment}-postgres-dns-link"
  resource_group_name   = azurerm_resource_group.db_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

# Create PostgreSQL database for Harbor
resource "azurerm_postgresql_flexible_server_database" "harbor_db" {
  name      = var.harbor_db_name
  server_id = azurerm_postgresql_flexible_server.postgres.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Configure PostgreSQL server parameters
resource "azurerm_postgresql_flexible_server_configuration" "log_connections" {
  name      = "log_connections"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_disconnections" {
  name      = "log_disconnections"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "connection_throttling" {
  name      = "connection_throttling"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_retention_days" {
  name      = "log_retention_days"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  value     = var.environment == "prod" ? "7" : "3"
}

# Configure firewall rules (only allow connections from AKS subnet)
resource "azurerm_postgresql_flexible_server_firewall_rule" "aks_subnet" {
  name             = "allow-aks-subnet"
  server_id        = azurerm_postgresql_flexible_server.postgres.id
  start_ip_address = cidrhost(var.aks_subnet_cidr, 0)
  end_ip_address   = cidrhost(var.aks_subnet_cidr, -1)
}

# Set up diagnostic settings for PostgreSQL
resource "azurerm_monitor_diagnostic_setting" "postgres_diag" {
  name                       = "${var.prefix}-${var.environment}-postgres-diag"
  target_resource_id         = azurerm_postgresql_flexible_server.postgres.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "PostgreSQLLogs"
  }
  
  enabled_log {
    category = "PostgreSQLFlexDatabaseXacts"
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