# modules/rbac/outputs.tf

output "aks_admins_group_id" {
  description = "Object ID of the AKS admins group"
  value       = azuread_group.aks_admins.id
}

output "harbor_admins_group_id" {
  description = "Object ID of the Harbor admins group"
  value       = azuread_group.harbor_admins.id
}

output "harbor_developers_group_id" {
  description = "Object ID of the Harbor developers group"
  value       = azuread_group.harbor_developers.id
}

output "harbor_sp_id" {
  description = "Application ID of the Harbor service principal"
  value       = azuread_service_principal.harbor_sp.application_id
  sensitive   = true
}

output "harbor_sp_object_id" {
  description = "Object ID of the Harbor service principal"
  value       = azuread_service_principal.harbor_sp.id
}