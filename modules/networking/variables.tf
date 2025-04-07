# modules/networking/variables.tf

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

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_cidr" {
  description = "CIDR for AKS subnet"
  type        = string
  default     = "10.0.0.0/22"
}

variable "db_subnet_cidr" {
  description = "CIDR for database subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "redis_subnet_cidr" {
  description = "CIDR for Redis subnet"
  type        = string
  default     = "10.0.5.0/24"
}