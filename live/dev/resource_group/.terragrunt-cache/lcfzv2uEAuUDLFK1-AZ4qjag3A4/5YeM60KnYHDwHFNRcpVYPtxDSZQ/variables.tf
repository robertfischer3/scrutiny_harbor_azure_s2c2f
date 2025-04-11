# modules/resource_group/variables.tf

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
  description = "Default Azure region"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "resource_groups" {
  description = "Map of resource groups to create"
  type = map(object({
    name     = string
    location = string
    tags     = map(string)
  }))
  default = {}
}

variable "create_terraform_storage" {
  description = "Whether to create a storage account for Terraform state"
  type        = bool
  default     = false
}

variable "terraform_storage_account_name" {
  description = "Name of the storage account for Terraform state"
  type        = string
  default     = "tfstateaccount"
}

variable "terraform_container_name" {
  description = "Name of the container for Terraform state"
  type        = string
  default     = "tfstate"
}