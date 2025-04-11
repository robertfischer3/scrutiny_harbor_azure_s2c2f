# modules/storage/outputs.tf

output "storage_account_id" {
  description = "ID of the Storage Account"
  value       = azurerm_storage_account.storage.id
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = azurerm_storage_account.storage.name
}

output "storage_account_primary_key" {
  description = "Primary access key for the Storage Account"
  value       = azurerm_storage_account.storage.primary_access_key
  sensitive   = true
}

output "storage_account_primary_connection_string" {
  description = "Primary connection string for the Storage Account"
  value       = azurerm_storage_account.storage.primary_connection_string
  sensitive   = true
}

output "registry_container_name" {
  description = "Name of the container for Harbor registry"
  value       = azurerm_storage_container.harbor_registry.name
}

output "chartmuseum_container_name" {
  description = "Name of the container for Harbor ChartMuseum"
  value       = azurerm_storage_container.harbor_chartmuseum.name
}

output "trivy_container_name" {
  description = "Name of the container for Harbor Trivy"
  value       = azurerm_storage_container.harbor_trivy.name
}

output "private_endpoint_ip" {
  description = "Private IP address of the Storage private endpoint"
  value       = var.environment == "prod" ? azurerm_private_endpoint.storage_pe[0].private_service_connection[0].private_ip_address : null
}
