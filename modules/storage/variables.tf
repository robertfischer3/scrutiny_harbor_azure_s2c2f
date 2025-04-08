# modules/storage/variables.tf

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "harbor"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "blob_soft_delete_retention_days" {
  description = "Number of days for blob soft delete retention"
  type        = number
  default     = 7
}

variable "container_soft_delete_retention_days" {
  description = "Number of days for container soft delete retention"
  type        = number
  default     = 7
}

variable "key_vault_key_id" {
  description = "ID of the Key Vault key for encryption"
  type        = string
}

variable "user_assigned_identity_id" {
  description = "ID of the user-assigned identity for Key Vault access"
  type        = string
}

variable "allowed_ip_addresses" {
  description = "List of allowed IP addresses"
  type        = list(string)
  default     = []
}

variable "aks_subnet_id" {
  description = "ID of the AKS subnet"
  type        = string
}

variable "vnet_id" {
  description = "ID of the virtual network"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of Log Analytics Workspace for diagnostics"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault to store storage credentials"
  type        = string
}