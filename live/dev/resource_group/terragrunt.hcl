# Terragrunt configuration for resource_group in dev environment

include {
  path = "${find_in_parent_folders("root.hcl")}"
}

# Terragrunt configuration for resource_group in dev environment

# Use local backend for bootstrapping
terraform {
  source = "../../../modules/resource_group"

  # Override the backend configuration to use local state
  # until we can create the Azure Storage backend
  extra_arguments "disable_backend" {
    commands = ["init"]
    arguments = ["-backend=false"]
  }
}

# Temporarily use local state instead of remote state
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "local" {}
}
EOF
}

generate "provider_resource_group" {
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
    },
    network = {
      name     = "harbor-dev-network-rg"
      location = "eastus"
      tags     = {
        Environment = "Development"
        Application = "Harbor"
        Component   = "Networking"
        ManagedBy   = "Terraform"
      }
    },
    common = {
      name     = "harbor-dev-common-rg"
      location = "eastus"
      tags     = {
        Environment = "Development"
        Application = "Harbor"
        Component   = "Common"
        ManagedBy   = "Terraform"
      }
    }
  }
  
  # Create storage account for terraform state
  create_terraform_storage = true
  terraform_storage_account_name = "tfstateaccount"
  terraform_container_name = "tfstate"
}