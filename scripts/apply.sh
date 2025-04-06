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
