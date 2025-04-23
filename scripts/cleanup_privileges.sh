#!/bin/bash
# This script removes the temporary User Access Administrator role from the service principal

echo "Removing temporary User Access Administrator role..."
source ".env"

if [ -z "$TEMP_ROLE_ASSIGNMENT_ID" ]; then
  echo "Error: Role assignment ID not found in .env"
  exit 1
fi

az role assignment delete --ids "$TEMP_ROLE_ASSIGNMENT_ID"
if [ $? -eq 0 ]; then
  echo "Successfully removed User Access Administrator role"
  # Remove the variable from the ENV_FILE
  sed -i '/TEMP_ROLE_ASSIGNMENT_ID/d' ".env"
else
  echo "Failed to remove the role. Please check and remove it manually."
fi
