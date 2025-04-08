# modules/harbor/variables.tf

variable "harbor_chart_version" {
  description = "Version of the Harbor Helm chart"
  type        = string
  default     = "1.12.2"
}

variable "harbor_domain" {
  description = "Domain name for Harbor"
  type        = string
}

variable "admin_password" {
  description = "Admin password for Harbor"
  type        = string
  sensitive   = true
}

variable "tls_cert_secret" {
  description = "Name of the secret containing TLS certificate and key"
  type        = string
  default     = ""
}

variable "tls_certificate" {
  description = "TLS certificate content (if not using existing secret)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tls_key" {
  description = "TLS key content (if not using existing secret)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "database_host" {
  description = "PostgreSQL database host"
  type        = string
}

variable "database_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "redis_host" {
  description = "Redis host"
  type        = string
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  sensitive   = true
}

variable "storage_class_name" {
  description = "Storage class name for persistent volumes"
  type        = string
  default     = "default"
}

variable "registry_storage" {
  description = "Type of storage for the registry (filesystem or azure)"
  type        = string
  default     = "filesystem"
}

variable "aks_depends_on" {
  description = "Resource to depend on for AKS to be ready"
  type        = any
  default     = null
}