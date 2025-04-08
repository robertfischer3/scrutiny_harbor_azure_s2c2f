# modules/redis/variables.tf

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

variable "redis_capacity" {
  description = "Redis capacity (size)"
  type        = number
  default     = 1
}

variable "redis_family" {
  description = "Redis family (C=Basic/Standard, P=Premium)"
  type        = string
  default     = "C"
}

variable "redis_sku" {
  description = "Redis SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "maxfrag_memory_reserved" {
  description = "Memory reserved for server fragmentation"
  type        = number
  default     = 50
}

variable "max_memory_reserved" {
  description = "Memory reserved for non-cache operations"
  type        = number
  default     = 50
}

variable "redis_subnet_id" {
  description = "ID of the subnet where Redis should be deployed"
  type        = string
}

variable "vnet_id" {
  description = "ID of the virtual network"
  type        = string
}

variable "aks_subnet_cidr" {
  description = "CIDR of the AKS subnet"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of Log Analytics Workspace for diagnostics"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault for storing Redis connection information"
  type        = string
}

variable "redis_password" {
  description = "Custom Redis password (if not using auto-generated)"
  type        = string
  sensitive   = true
  default     = null
}