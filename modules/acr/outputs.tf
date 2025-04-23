# modules/acr/outputs.tf

output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "Admin username for the Azure Container Registry"
  value       = var.admin_enabled ? azurerm_container_registry.acr.admin_username : null
}

output "acr_admin_password" {
  description = "Admin password for the Azure Container Registry"
  value       = var.admin_enabled ? azurerm_container_registry.acr.admin_password : null
  sensitive   = true
}

output "acr_scope_map_id" {
  description = "ID of the ACR scope map for Harbor"
  value       = azurerm_container_registry_scope_map.harbor_scope.id
}

output "acr_token_id" {
  description = "ID of the ACR token for Harbor"
  value       = azurerm_container_registry_token.harbor_token.id
}

output "acr_private_endpoint_ip" {
  description = "Private IP address of the ACR private endpoint (production only)"
  value       = var.environment == "prod" ? azurerm_private_endpoint.acr_pe[0].private_service_connection[0].private_ip_address : null
}

output "acr_resource_group_name" {
  description = "Name of the ACR resource group"
  value       = azurerm_resource_group.acr_rg.name
}