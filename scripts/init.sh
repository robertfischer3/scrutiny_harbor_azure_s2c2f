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
