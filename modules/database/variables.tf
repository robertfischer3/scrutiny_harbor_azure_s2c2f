# modules/database/variables.tf

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

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "14"
}

variable "postgres_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  default     = "postgres"
}

variable "postgres_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768  # 32GB
}

variable "postgres_sku" {
  description = "PostgreSQL SKU name"
  type        = string
  default     = "B_Standard_B1ms"  # Default to basic tier for dev
}

variable "availability_zone" {
  description = "Availability zone for PostgreSQL"
  type        = string
  default     = "1"
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

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "harbor_db_name" {
  description = "Name of the Harbor database"
  type        = string
  default     = "harbor"
}

variable "vnet_id" {
  description = "ID of the virtual network"
  type        = string
}

variable "db_subnet_id" {
  description = "ID of the database subnet"
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