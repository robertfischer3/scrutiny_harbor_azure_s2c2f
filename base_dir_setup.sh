#!/bin/bash

# Script to create Harbor Infrastructure directory structure
# for S2C2F Level 3 compliance on Azure

# Set base directory
BASE_DIR="scrutiny_harbor-azure-s2c2f"

# Create base directory
# mkdir -p "$BASE_DIR"

# Create top-level directories
mkdir -p "$BASE_DIR/_env"
mkdir -p "$BASE_DIR/modules"
mkdir -p "$BASE_DIR/live"
mkdir -p "$BASE_DIR/policies"
mkdir -p "$BASE_DIR/scripts"
mkdir -p "$BASE_DIR/docs"

# Create environment variable files
touch "$BASE_DIR/_env/dev.tfvars"
touch "$BASE_DIR/_env/staging.tfvars"
touch "$BASE_DIR/_env/prod.tfvars"

# Create root Terragrunt config
cat > "$BASE_DIR/terragrunt.hcl" << 'EOL'
# Root Terragrunt configuration

remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateaccount"
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
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

# Configure Terragrunt to automatically format Terraform code
terraform {
  before_hook "before_hook" {
    commands = ["apply", "plan"]
    execute  = ["terraform", "fmt", "-recursive"]
  }
}
EOL

# Create module directories and files
MODULE_DIRS=("networking" "aks" "acr" "storage" "database" "redis" "key_vault" "monitoring" "harbor")

for module in "${MODULE_DIRS[@]}"; do
  mkdir -p "$BASE_DIR/modules/$module"
  touch "$BASE_DIR/modules/$module/main.tf"
  touch "$BASE_DIR/modules/$module/variables.tf"
  touch "$BASE_DIR/modules/$module/outputs.tf"
done

# Create live environment directories and files
ENV_DIRS=("dev" "staging" "prod")
SUB_DIRS=("resource_group" "networking" "aks" "acr" "storage" "database" "redis" "key_vault" "monitoring" "harbor")

for env in "${ENV_DIRS[@]}"; do
  mkdir -p "$BASE_DIR/live/$env"
  
  # Create environment terragrunt.hcl
  cat > "$BASE_DIR/live/$env/terragrunt.hcl" << EOL
# Terragrunt configuration for $env environment

include {
  path = find_in_parent_folders()
}

inputs = {
  environment = "$env"
  # Additional environment-specific variables can be defined here
}
EOL

  # Create subdirectories with terragrunt.hcl files
  for sub_dir in "${SUB_DIRS[@]}"; do
    mkdir -p "$BASE_DIR/live/$env/$sub_dir"
    
    cat > "$BASE_DIR/live/$env/$sub_dir/terragrunt.hcl" << EOL
# Terragrunt configuration for $sub_dir in $env environment

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/$sub_dir"
}

dependencies {
  paths = [
    # Define dependencies as needed
  ]
}

inputs = {
  # Module-specific inputs
}
EOL
  done
done

# Create policy directories and files
POLICY_DIRS=("image_scanning" "artifact_signing" "rbac" "network_policies")

for policy in "${POLICY_DIRS[@]}"; do
  mkdir -p "$BASE_DIR/policies/$policy"
  touch "$BASE_DIR/policies/$policy/policy.tf"
done

# Create scripts with basic content
cat > "$BASE_DIR/scripts/init.sh" << 'EOL'
#!/bin/bash
# Initialization script for Harbor S2C2F infrastructure

set -e

echo "Initializing Harbor S2C2F infrastructure..."

# Navigate to the environment directory
if [ -z "$1" ]; then
  echo "Usage: $0 <environment>"
  echo "Example: $0 dev"
  exit 1
fi

ENV_DIR="../live/$1"

if [ ! -d "$ENV_DIR" ]; then
  echo "Environment directory not found: $ENV_DIR"
  exit 1
fi

cd "$ENV_DIR"

# Run terragrunt init in each subdirectory
find . -type d -name "*" -mindepth 1 -maxdepth 1 | while read -r dir; do
  echo "Initializing $dir..."
  cd "$dir"
  terragrunt init
  cd ..
done

echo "Initialization complete!"
EOL

cat > "$BASE_DIR/scripts/apply.sh" << 'EOL'
#!/bin/bash
# Apply script for Harbor S2C2F infrastructure

set -e

echo "Applying Harbor S2C2F infrastructure..."

# Navigate to the environment directory
if [ -z "$1" ]; then
  echo "Usage: $0 <environment>"
  echo "Example: $0 dev"
  exit 1
fi

ENV_DIR="../live/$1"

if [ ! -d "$ENV_DIR" ]; then
  echo "Environment directory not found: $ENV_DIR"
  exit 1
fi

cd "$ENV_DIR"

# Run terragrunt apply in each subdirectory or all at once
if [ "$2" == "all" ]; then
  echo "Applying all components..."
  terragrunt run-all apply
else
  echo "Applying components one by one..."
  find . -type d -name "*" -mindepth 1 -maxdepth 1 | while read -r dir; do
    echo "Applying $dir..."
    cd "$dir"
    terragrunt apply
    cd ..
  done
fi

echo "Apply complete!"
EOL

cat > "$BASE_DIR/scripts/destroy.sh" << 'EOL'
#!/bin/bash
# Destroy script for Harbor S2C2F infrastructure

set -e

echo "Destroying Harbor S2C2F infrastructure..."

# Navigate to the environment directory
if [ -z "$1" ]; then
  echo "Usage: $0 <environment>"
  echo "Example: $0 dev"
  exit 1
fi

ENV_DIR="../live/$1"

if [ ! -d "$ENV_DIR" ]; then
  echo "Environment directory not found: $ENV_DIR"
  exit 1
fi

cd "$ENV_DIR"

# Run terragrunt destroy in each subdirectory or all at once
if [ "$2" == "all" ]; then
  echo "Destroying all components..."
  terragrunt run-all destroy
else
  echo "Destroying components one by one in reverse order..."
  find . -type d -name "*" -mindepth 1 -maxdepth 1 | sort -r | while read -r dir; do
    echo "Destroying $dir..."
    cd "$dir"
    terragrunt destroy
    cd ..
  done
fi

echo "Destroy complete!"
EOL

# Make scripts executable
chmod +x "$BASE_DIR/scripts/init.sh"
chmod +x "$BASE_DIR/scripts/apply.sh"
chmod +x "$BASE_DIR/scripts/destroy.sh"

# Create documentation files with basic content
cat > "$BASE_DIR/docs/architecture.md" << 'EOL'
# Harbor S2C2F Architecture

This document describes the architecture of the Harbor deployment on Azure, designed to meet Level 3 maturity in the S2C2F framework.

## Overview

The architecture is built around a Harbor registry deployed on Azure Kubernetes Service (AKS) with supporting services:

- Azure Database for PostgreSQL for the database
- Azure Cache for Redis for caching
- Azure Storage for persistent storage
- Azure Key Vault for secrets management
- Azure Container Registry as a backup registry

## Network Architecture

[Network architecture description]

## Security Controls

[Security controls description]

## High Availability

[High availability architecture]

## Monitoring and Logging

[Monitoring and logging architecture]
EOL

cat > "$BASE_DIR/docs/security_compliance.md" << 'EOL'
# S2C2F Level 3 Compliance Documentation

This document details how our Harbor implementation meets the requirements of S2C2F Level 3 maturity.

## S2C2F Level 3 Requirements

Level 3 represents "comprehensive governance of OSS components" and focuses on proactive security measures and segregation of software until it's been properly tested and secured.

## Compliance Matrix

| Requirement | Implementation | Status |
|-------------|----------------|--------|
| [Requirement 1] | [Implementation details] | [Status] |
| [Requirement 2] | [Implementation details] | [Status] |
| [Requirement 3] | [Implementation details] | [Status] |

## Security Controls

[Security controls details]

## Auditing and Compliance Monitoring

[Auditing and compliance monitoring details]
EOL

cat > "$BASE_DIR/docs/operation_manual.md" << 'EOL'
# Harbor Operations Manual

This manual provides instructions for operating the Harbor registry infrastructure.

## Deployment

### Prerequisites

- Azure subscription
- Terraform 1.0.0 or later
- Terragrunt 0.35.0 or later
- Azure CLI

### Deployment Process

1. Initialize the infrastructure:
