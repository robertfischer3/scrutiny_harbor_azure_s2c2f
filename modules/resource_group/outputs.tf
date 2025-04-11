# modules/resource_group/outputs.tf

output "resource_group_ids" {
  description = "IDs of the created resource groups"
  value       = { for k, v in azurerm_resource_group.resource_groups : k => v.id }
}

output "resource_group_names" {
  description = "Names of the created resource groups"
  value       = { for k, v in azurerm_resource_group.resource_groups : k => v.name }
}

output "terraform_storage_account_id" {
  description = "ID of the Terraform state storage account"
  value       = var.create_terraform_storage ? azurerm_storage_account.terraform_storage[0].id : null
}

output "terraform_storage_account_name" {
  description = "Name of the Terraform state storage account"
  value       = var.create_terraform_storage ? azurerm_storage_account.terraform_storage[0].name : null
}

output "terraform_container_name" {
  description = "Name of the Terraform state container"
  value       = var.create_terraform_storage ? azurerm_container_name.terraform_container[0].name : null
}

output "terraform_storage_account_key" {
  description = "Primary access key for the Terraform state storage account"
  value       = var.create_terraform_storage ? azurerm_storage_account.terraform_storage[0].primary_access_key : null
  sensitive   = true
}