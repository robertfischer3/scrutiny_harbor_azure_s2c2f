# modules/redis/outputs.tf

output "redis_id" {
  description = "ID of the Redis Cache"
  value       = azurerm_redis_cache.redis.id
}

output "redis_name" {
  description = "Name of the Redis Cache"
  value       = azurerm_redis_cache.redis.name
}

output "redis_hostname" {
  description = "Hostname of the Redis Cache"
  value       = azurerm_redis_cache.redis.hostname
}

output "redis_ssl_port" {
  description = "SSL port of the Redis Cache"
  value       = azurerm_redis_cache.redis.ssl_port
}

output "redis_primary_key" {
  description = "Primary access key for the Redis Cache"
  value       = azurerm_redis_cache.redis.primary_access_key
  sensitive   = true
}

output "redis_connection_string" {
  description = "Connection string for the Redis Cache"
  value       = "${azurerm_redis_cache.redis.hostname}:${azurerm_redis_cache.redis.ssl_port},password=${azurerm_redis_cache.redis.primary_access_key},ssl=True,abortConnect=False"
  sensitive   = true
}

output "redis_private_endpoint_ip" {
  description = "Private IP address of the Redis private endpoint"
  value       = azurerm_redis_cache.redis.private_endpoint[0].private_service_connection[0].private_ip_address
}