# modules/redis/main.tf

# Create Resource Group for Redis
resource "azurerm_resource_group" "redis_rg" {
  name     = "${var.prefix}-${var.environment}-redis-rg"
  location = var.location
  tags     = var.tags
}

# Create Azure Cache for Redis
resource "azurerm_redis_cache" "redis" {
  name                = "${var.prefix}-${var.environment}-redis"
  location            = azurerm_resource_group.redis_rg.location
  resource_group_name = azurerm_resource_group.redis_rg.name
  capacity            = var.redis_capacity
  family              = var.redis_family
  sku_name            = var.redis_sku
  minimum_tls_version = "1.2"
  
  # Security for S2C2F Level 3 compliance
  public_network_access_enabled = false
  
  # Redis configuration
  redis_configuration {
    maxmemory_policy      = "volatile-lru"
    maxfragmentationmemory_reserved = var.maxfrag_memory_reserved
    maxmemory_reserved              = var.max_memory_reserved
  }
    
  
  tags = var.tags
}

# Create Private Endpoint as a separate resource
resource "azurerm_private_endpoint" "redis_pe" {
  name                = "${var.prefix}-${var.environment}-redis-pe"
  location            = azurerm_resource_group.redis_rg.location
  resource_group_name = azurerm_resource_group.redis_rg.name
  subnet_id           = var.redis_subnet_id

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-redis-psc"
    private_connection_resource_id = azurerm_redis_cache.redis.id
    is_manual_connection           = false
    subresource_names              = ["redisCache"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis.id]
  }
}

# Create Private DNS Zone for Redis
resource "azurerm_private_dns_zone" "redis" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = azurerm_resource_group.redis_rg.name
  tags                = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "redis_dns_link" {
  name                  = "${var.prefix}-${var.environment}-redis-dns-link"
  resource_group_name   = azurerm_resource_group.redis_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

# Create diagnostic settings for Redis
resource "azurerm_monitor_diagnostic_setting" "redis_diag" {
  name                       = "${var.prefix}-${var.environment}-redis-diag"
  target_resource_id         = azurerm_redis_cache.redis.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "ConnectedClientList"
  }
  
  enabled_log {
    category = "RedisRequests"
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

# Store Redis connection information in Key Vault
resource "azurerm_key_vault_secret" "redis_connection_string" {
  name         = "${var.prefix}-${var.environment}-redis-connection"
  value        = "${azurerm_redis_cache.redis.hostname}:${azurerm_redis_cache.redis.ssl_port},password=${azurerm_redis_cache.redis.primary_access_key},ssl=True,abortConnect=False"
  key_vault_id = var.key_vault_id
  
  # Set expiration date for secrets
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now
  
  # Apply tags
  tags = merge(var.tags, {
    secret_type = "connection-string"
    application = "harbor"
  })
}

# Create Redis cache firewall rules
resource "azurerm_redis_firewall_rule" "aks_subnet" {
  name                = "allow-aks-subnet"
  redis_cache_name    = azurerm_redis_cache.redis.name
  resource_group_name = azurerm_resource_group.redis_rg.name
  start_ip            = cidrhost(var.aks_subnet_cidr, 0)
  end_ip              = cidrhost(var.aks_subnet_cidr, -1)
}