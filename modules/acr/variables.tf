# modules/acr/variables.tf

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

variable "sku" {
  description = "SKU for ACR (Basic, Standard, Premium)"
  type        = string
  default     = "Premium"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "The SKU must be one of: Basic, Standard, Premium."
  }
}

variable "admin_enabled" {
  description = "Enable admin user for ACR"
  type        = bool
  default     = false
}

variable "retention_days" {
  description = "Number of days to retain images"
  type        = number
  default     = 30
}

variable "network_default_action" {
  description = "Default action for network rules (Allow or Deny)"
  type        = string
  default     = "Deny"
  validation {
    condition     = contains(["Allow", "Deny"], var.network_default_action)
    error_message = "The network_default_action must be either Allow or Deny."
  }
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access ACR"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access ACR"
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

variable "key_vault_id" {
  description = "ID of the Key Vault to store ACR credentials"
  type        = string
}

variable "key_vault_key_id" {
  description = "ID of the Key Vault key for encryption"
  type        = string
  default     = null
}

variable "user_assigned_identity_id" {
  description = "ID of the user-assigned identity for Key Vault access"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "ID of Log Analytics Workspace for diagnostics"
  type        = string
}

variable "geo_replications" {
  description = "List of geo-replications for ACR"
  type = list(object({
    location                = string
    zone_redundancy_enabled = bool
    tags                    = map(string)
  }))
  default = []
}