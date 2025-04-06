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
