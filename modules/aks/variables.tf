# modules/aks/variables.tf

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

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.3"
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "system_node_count" {
  description = "Initial number of system nodes"
  type        = number
  default     = 3
}

variable "system_node_min_count" {
  description = "Minimum number of system nodes"
  type        = number
  default     = 3
}

variable "system_node_max_count" {
  description = "Maximum number of system nodes"
  type        = number
  default     = 5
}

variable "system_node_vm_size" {
  description = "VM size for system nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "user_node_count" {
  description = "Initial number of user nodes"
  type        = number
  default     = 2
}

variable "user_node_min_count" {
  description = "Minimum number of user nodes"
  type        = number
  default     = 2
}

variable "user_node_max_count" {
  description = "Maximum number of user nodes"
  type        = number
  default     = 5
}

variable "user_node_vm_size" {
  description = "VM size for user nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

variable "subnet_id" {
  description = "ID of the subnet where AKS should be deployed"
  type        = string
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.0.128.0/20"
}

variable "dns_service_ip" {
  description = "IP address for Kubernetes DNS service"
  type        = string
  default     = "10.0.128.10"
}

variable "docker_bridge_cidr" {
  description = "CIDR for Docker bridge network"
  type        = string
  default     = "172.17.0.1/16"
}

variable "admin_group_object_ids" {
  description = "List of Azure AD group object IDs for AKS admins"
  type        = list(string)
  default     = []
}

variable "harbor_admin_group_id" {
  description = "Azure AD group object ID for Harbor admins"
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault containing Harbor secrets"
  type        = string
}