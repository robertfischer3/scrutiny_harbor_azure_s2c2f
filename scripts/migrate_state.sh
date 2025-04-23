#!/bin/bash
# migrate_state.sh - Migrates the local state to Azure Storage

set -e

echo "Migrating Terraform state to Azure..."

# Navigate to the resource_group directory
cd ../live/dev/resource_group

# Backup the current state file
if [ -f "terraform.tfstate" ]; then
  cp terraform.tfstate terraform.tfstate.backup
  echo "Backed up local state file to terraform.tfstate.backup"
fi

# Check if root.hcl has been updated
echo "Before proceeding, please ensure you have updated the root.hcl file with the correct backend configuration"
read -p "Have you updated root.hcl? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Please update root.hcl first, then run this script again"
  exit 1
fi

# Perform the migration
echo "Migrating state..."
terragrunt init -migrate-state

echo "State migration complete!"
echo "You can now run the regular init.sh script for the rest of the infrastructure"