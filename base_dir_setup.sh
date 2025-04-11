#!/bin/bash

# Updated script to set up or update Harbor Infrastructure directory structure
# for S2C2F Level 3 compliance on Azure
# This version preserves existing terragrunt.hcl files and other configurations

# Set base directory - use current directory
BASE_DIR="."

# Function to create directory if it doesn't exist
create_dir_if_not_exists() {
  if [ ! -d "$1" ]; then
    echo "Creating directory: $1"
    mkdir -p "$1"
  else
    echo "Directory already exists: $1"
  fi
}

# Function to create file if it doesn't exist
create_file_if_not_exists() {
  if [ ! -f "$1" ]; then
    echo "Creating file: $1"
    touch "$1"
  else
    echo "File already exists: $1"
  fi
}

# Function to write content to file if file doesn't exist
write_file_if_not_exists() {
  local file="$1"
  local content="$2"
  
  if [ ! -f "$file" ]; then
    echo "Creating file with content: $file"
    echo "$content" > "$file"
  else
    echo "File already exists (preserving): $file"
  fi
}

echo "Setting up/updating Harbor Infrastructure directory structure..."
echo "Note: Existing terragrunt.hcl files and other configurations will be preserved."

# Create top-level directories
create_dir_if_not_exists "$BASE_DIR/_env"
create_dir_if_not_exists "$BASE_DIR/modules"
create_dir_if_not_exists "$BASE_DIR/live"
create_dir_if_not_exists "$BASE_DIR/policies"
create_dir_if_not_exists "$BASE_DIR/scripts"
create_dir_if_not_exists "$BASE_DIR/docs"

# Create environment variable files
create_file_if_not_exists "$BASE_DIR/_env/dev.tfvars"
create_file_if_not_exists "$BASE_DIR/_env/staging.tfvars"
create_file_if_not_exists "$BASE_DIR/_env/prod.tfvars"

# Create root Terragrunt config if not exists
write_file_if_not_exists "$BASE_DIR/root.hcl" 'remote_state {
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
}'

# Create module directories and files
MODULE_DIRS=("networking" "aks" "acr" "storage" "database" "redis" "key_vault" "monitoring" "harbor" "resource_group" "rbac")

for module in "${MODULE_DIRS[@]}"; do
  create_dir_if_not_exists "$BASE_DIR/modules/$module"
  create_file_if_not_exists "$BASE_DIR/modules/$module/main.tf"
  create_file_if_not_exists "$BASE_DIR/modules/$module/variables.tf"
  create_file_if_not_exists "$BASE_DIR/modules/$module/outputs.tf"
done

# Create live environment directories
ENV_DIRS=("dev" "staging" "prod")
SUB_DIRS=("resource_group" "networking" "aks" "acr" "storage" "database" "redis" "key_vault" "monitoring" "harbor" "rbac")

for env in "${ENV_DIRS[@]}"; do
  create_dir_if_not_exists "$BASE_DIR/live/$env"
  
  # Create environment terragrunt.hcl if it doesn't exist
  terragrunt_file="$BASE_DIR/live/$env/terragrunt.hcl"
  write_file_if_not_exists "$terragrunt_file" "# Terragrunt configuration for $env environment

include {
  path = find_in_parent_folders()
}

# Local variables for $env environment
locals {
  # These would be populated from environment variables during CI/CD
  harbor_admin_password = get_env(\"HARBOR_ADMIN_PASSWORD\")
  harbor_db_password    = get_env(\"HARBOR_DB_PASSWORD\")
  harbor_redis_password = get_env(\"HARBOR_REDIS_PASSWORD\")
}

inputs = {
  environment            = \"$env\"
  harbor_admin_password = local.harbor_admin_password
  harbor_db_password    = local.harbor_db_password
  harbor_redis_password = local.harbor_redis_password
  # Other $env environment variables
}"

  # Create subdirectories with terragrunt.hcl files
  for sub_dir in "${SUB_DIRS[@]}"; do
    create_dir_if_not_exists "$BASE_DIR/live/$env/$sub_dir"
    
    # Check if terragrunt.hcl already exists in this directory
    sub_terragrunt_file="$BASE_DIR/live/$env/$sub_dir/terragrunt.hcl"
    
    # Only create the file if it doesn't exist - this preserves existing terragrunt configurations
    if [ ! -f "$sub_terragrunt_file" ]; then
      if [ "$sub_dir" == "resource_group" ] && [ "$env" == "dev" ]; then
        # Special case for resource_group in dev to use local backend
        echo "Creating special resource_group terragrunt.hcl for dev environment"
        cat > "$sub_terragrunt_file" << 'EOF'
# Terragrunt configuration for resource_group in dev environment

include {
  path = find_in_parent_folders()
}

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
EOF
      else
        # Regular configuration for other components or environments
        echo "Creating default terragrunt.hcl for $env/$sub_dir"
        cat > "$sub_terragrunt_file" << EOF
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
EOF
      fi
    else
      echo "Preserving existing terragrunt.hcl file: $sub_terragrunt_file"
    fi
  done
done

# Create policy directories
POLICY_DIRS=("image_scanning" "artifact_signing" "rbac" "network_policies")

for policy in "${POLICY_DIRS[@]}"; do
  create_dir_if_not_exists "$BASE_DIR/policies/$policy"
  create_file_if_not_exists "$BASE_DIR/policies/$policy/policy.tf"
done

# Create or update scripts, but don't overwrite existing ones
# Create init.sh script if it doesn't exist
init_script="$BASE_DIR/scripts/init.sh"
if [ ! -f "$init_script" ]; then
  echo "Creating init.sh script"
  cat > "$init_script" << 'EOF'
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
find . -mindepth 1 -maxdepth 1 -type d -name "*" | while read -r dir; do
  echo "Initializing $dir..."
  cd "$dir"
  terragrunt init
  cd ..
done

echo "Initialization complete!"
EOF
else
  echo "Preserving existing init.sh script"
fi

# Create apply.sh if it doesn't exist
apply_script="$BASE_DIR/scripts/apply.sh"
if [ ! -f "$apply_script" ]; then
  echo "Creating apply.sh script"
  cat > "$apply_script" << 'EOF'
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
  find . -mindepth 1 -maxdepth 1 -type d -name "*" | while read -r dir; do
    echo "Applying $dir..."
    cd "$dir"
    terragrunt apply
    cd ..
  done
fi

echo "Apply complete!"
EOF
else
  echo "Preserving existing apply.sh script"
fi

# Create destroy.sh if it doesn't exist
destroy_script="$BASE_DIR/scripts/destroy.sh"
if [ ! -f "$destroy_script" ]; then
  echo "Creating destroy.sh script"
  cat > "$destroy_script" << 'EOF'
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
  find . -mindepth 1 -maxdepth 1 -type d -name "*" | sort -r | while read -r dir; do
    echo "Destroying $dir..."
    cd "$dir"
    terragrunt destroy
    cd ..
  done
fi

echo "Destroy complete!"
EOF
else
  echo "Preserving existing destroy.sh script"
fi

# Make scripts executable, even if they already existed
chmod +x "$BASE_DIR/scripts/init.sh"
chmod +x "$BASE_DIR/scripts/apply.sh"
chmod +x "$BASE_DIR/scripts/destroy.sh"
chmod +x "$BASE_DIR/scripts/bootstrap.sh"
chmod +x "$BASE_DIR/scripts/migrate_state.sh"

echo "Directory structure setup/update complete!"
echo "Existing files have been preserved."