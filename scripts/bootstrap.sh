#!/bin/bash
# bootstrap.sh - Creates only the base infrastructure for Terraform state

set -e

echo "Bootstrapping Terraform state infrastructure..."

# Navigate to the resource_group directory
cd ../live/dev/resource_group

# Clean up any previous state
rm -f .terraform.lock.hcl
rm -rf .terraform
rm -f terraform.tfstate*
rm -rf .terragrunt-cache

# Initialize and apply Terraform
echo "Initializing..."
terragrunt init -reconfigure

echo "Planning changes..."
terragrunt plan

echo "Creating resources..."
terragrunt apply -auto-approve

# Get the storage account key for the migration instructions
STORAGE_ACCOUNT_KEY=$(terragrunt output -raw terraform_storage_account_key)
STORAGE_ACCOUNT_NAME=$(terragrunt output -raw terraform_storage_account_name)
RESOURCE_GROUP_NAME=$(terragrunt output -json resource_group_names | jq -r '.tfstate')
CONTAINER_NAME=$(terragrunt output -raw terraform_container_name)

echo "Bootstrap complete!"
echo "Resource group and storage account for Terraform state have been created."
echo ""
echo "Next steps:"
echo "1. Update your root.hcl with the following backend configuration:"
echo ""
echo "remote_state {"
echo "  backend = \"azurerm\""
echo "  generate = {"
echo "    path      = \"backend.tf\""
echo "    if_exists = \"overwrite_terragrunt\""
echo "  }"
echo "  config = {"
echo "    resource_group_name  = \"$RESOURCE_GROUP_NAME\""
echo "    storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "    container_name       = \"$CONTAINER_NAME\""
echo "    key                  = \"\${path_relative_to_include()}/terraform.tfstate\""
echo "  }"
echo "}"
echo ""
echo "2. Migrate the local state to Azure:"
echo "cd ../live/dev/resource_group"
echo "terragrunt init -migrate-state"
echo ""
echo "3. Now you can run the init.sh script for the rest of the infrastructure."