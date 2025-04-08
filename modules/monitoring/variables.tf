# modules/monitoring/variables.tf

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

variable "aks_cluster_id" {
  description = "ID of the AKS cluster to monitor"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault to monitor"
  type        = string
}

variable "database_id" {
  description = "ID of the PostgreSQL database to monitor"
  type        = string
  default     = ""
}

variable "redis_id" {
  description = "ID of the Redis cache to monitor"
  type        = string
  default     = ""
}

variable "acr_id" {
  description = "ID of the Azure Container Registry to monitor"
  type        = string
  default     = ""
}

variable "storage_account_id" {
  description = "ID of the Storage Account to monitor"
  type        = string
  default     = ""
}

variable "log_analytics_sku" {
  description = "SKU for Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "security_email" {
  description = "Email address for security alerts"
  type        = string
  default     = "security-team@example.com"
}

variable "sms_country_code" {
  description = "Country code for SMS notifications"
  type        = string
  default     = "1"
}

variable "sms_phone_number" {
  description = "Phone number for SMS notifications"
  type        = string
  default     = "5555555555"
}

variable "webhook_url" {
  description = "Webhook URL for alert notifications"
  type        = string
  default     = "https://example.webhook.com/endpoint"
}

variable "allowed_ip_ranges" {
  description = "List of IP addresses allowed to access storage accounts"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access storage accounts"
  type        = list(string)
  default     = []
}

variable "enable_vulnerability_scanning" {
  description = "Enable vulnerability scanning alerts"
  type        = bool
  default     = true
}

variable "enable_audit_policy" {
  description = "Enable audit policy for AKS"
  type        = bool
  default     = true
}

variable "audit_retention_days" {
  description = "Number of days to retain audit logs in long-term storage"
  type        = number
  default     = 365
}

variable "alert_severity_threshold" {
  description = "Minimum severity level for alerts (1: Critical, 2: Error, 3: Warning, 4: Informational)"
  type        = number
  default     = 2
}

variable "daily_quota_gb" {
  description = "Daily quota in GB for the Log Analytics Workspace"
  type        = number
  default     = 5
}

variable "create_dashboard" {
  description = "Create Azure Portal dashboard"
  type        = bool
  default     = true
}