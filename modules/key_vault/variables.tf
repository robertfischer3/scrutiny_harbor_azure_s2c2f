# modules/key_vault/variables.tf

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

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access Key Vault"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access Key Vault"
  type        = list(string)
  default     = []
}

variable "aks_identity_principal_id" {
  description = "Principal ID of the AKS identity"
  type        = string
  default     = null
}

variable "harbor_admin_password" {
  description = "Admin password for Harbor"
  type        = string
  sensitive   = true
}

variable "harbor_db_password" {
  description = "Database password for Harbor"
  type        = string
  sensitive   = true
}

variable "harbor_redis_password" {
  description = "Redis password for Harbor"
  type        = string
  sensitive   = true
}

variable "harbor_tls_cert" {
  description = "TLS certificate for Harbor"
  type        = string
  default     = null
  sensitive   = true
}

variable "harbor_tls_key" {
  description = "TLS key for Harbor"
  type        = string
  default     = null
  sensitive   = true
}

variable "log_analytics_workspace_id" {
  description = "ID of Log Analytics Workspace for diagnostics"
  type        = string
}