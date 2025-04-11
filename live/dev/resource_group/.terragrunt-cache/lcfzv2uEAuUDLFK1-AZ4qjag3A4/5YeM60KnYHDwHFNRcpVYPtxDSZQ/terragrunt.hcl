# live/dev/resource_group/terragrunt.hcl

# Explicitly use local backend - do NOT include root.hcl
terraform {
  source = "../../../modules/resource_group"
}

# Specify local backend
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "local" {}
}
EOF
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  features {}
}
EOF
}

inputs = {
  # Basic configuration
  environment = "dev"
  location    = "eastus"
  prefix      = "harbor"
  
  # Resource groups to create
  resource_groups = {
    tfstate = {
      name     = "terraform-state-rg"
      location = "eastus"
      tags     = {
        Environment = "Shared"
        Application = "Terraform"
        ManagedBy   = "Terraform"
      }
    }
  }
  
  # Create storage account for terraform state
  create_terraform_storage = true
  terraform_storage_account_name = "tfstateaccount"
  terraform_container_name = "tfstate"
}