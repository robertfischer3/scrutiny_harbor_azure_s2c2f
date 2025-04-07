# modules/networking/outputs.tf

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.vnet.name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks_subnet.id
}

output "db_subnet_id" {
  description = "ID of the database subnet"
  value       = azurerm_subnet.db_subnet.id
}

output "redis_subnet_id" {
  description = "ID of the Redis subnet"
  value       = azurerm_subnet.redis_subnet.id
}

output "network_resource_group_name" {
  description = "Name of the network resource group"
  value       = azurerm_resource_group.network_rg.name
}