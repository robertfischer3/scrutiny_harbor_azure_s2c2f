# Terragrunt configuration for RBAC

include {
  path = find_in_parent_folders("dev_config.hcl")
}

terraform {
  source = "../../../modules/rbac"
}

# Define dependencies on other modules
dependencies {
  paths = [
    "../aks",
    "../acr",
    "../key_vault",
    "../resource_group"
  ]
}

# Declare dependency blocks to access outputs
dependency "aks" {
  config_path = "../aks"
}

dependency "acr" {
  config_path = "../acr"
}

dependency "key_vault" {
  config_path = "../key_vault"
}

dependency "resource_group" {
  config_path = "../resource_group"
}

# Module inputs
inputs = {
  # Reference values from other modules using dependencies
  environment = local.env_vars.environment
  prefix      = "harbor"
  location    = "eastus"
  
  # AKS and ACR IDs from dependencies
  aks_cluster_id = dependency.aks.outputs.aks_id
  acr_id         = dependency.acr.outputs.acr_id
  key_vault_id   = dependency.key_vault.outputs.key_vault_id
  
  # RBAC specific configurations
  admin_group_name = "harbor-${local.env_vars.environment}-admins"
  developer_group_name = "harbor-${local.env_vars.environment}-developers"
  reader_group_name = "harbor-${local.env_vars.environment}-readers"
  
  # Role assignments
  create_admin_group = true
  create_developer_group = true
  create_reader_group = true
  
  # Azure AD configuration
  aad_integration_enabled = true
  
  # Service principal configuration
  create_harbor_sp = true
  
  # Tags
  tags = {
    Environment = title(local.env_vars.environment)
    Application = "Harbor"
    Component   = "RBAC"
    ManagedBy   = "Terraform"
    Compliance  = "S2C2F-Level3"
  }
}

# Local variables for this module
locals {
  # Extract environment variables from the parent
  env_vars = read_terragrunt_config(find_in_parent_folders("dev_config.hcl"))
}