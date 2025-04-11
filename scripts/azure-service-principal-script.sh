#!/bin/bash
# Azure Service Principal Setup Script for Terragrunt/Terraform Harbor Deployment
# This script creates a service principal with the necessary permissions
# to deploy the Harbor infrastructure on Azure

set -e

# Configuration variables
SUBSCRIPTION_ID=""
SP_NAME="harbor-terraform-sp"
RESOURCE_GROUP="terraform-state-rg" # Resource group for Terraform state
ENV_FILE=".env"
SUBSCRIPTION_SCOPE=""
EXPIRY_YEARS=1

# Text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display usage information
display_usage() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -s, --subscription-id ID   Azure subscription ID"
    echo "  -n, --name NAME            Service principal name (default: harbor-terraform-sp)"
    echo "  -r, --resource-group NAME  Resource group name (default: terraform-state-rg)"
    echo "  -o, --output FILE          Output file for environment variables (default: .env)"
    echo "  -y, --years YEARS          Secret expiry in years (default: 1)"
    echo "  -h, --help                 Display this help message"
    echo
    echo "Example:"
    echo "  $0 -s 12345678-1234-1234-1234-123456789012"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -s|--subscription-id)
            SUBSCRIPTION_ID="$2"
            shift
            shift
            ;;
        -n|--name)
            SP_NAME="$2"
            shift
            shift
            ;;
        -r|--resource-group)
            RESOURCE_GROUP="$2"
            shift
            shift
            ;;
        -o|--output)
            ENV_FILE="$2"
            shift
            shift
            ;;
        -y|--years)
            EXPIRY_YEARS="$2"
            shift
            shift
            ;;
        -h|--help)
            display_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            display_usage
            exit 1
            ;;
    esac
done

# Check if az CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed.${NC}"
    echo "Please install Azure CLI first: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if user is logged in to Azure
echo "Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}You are not logged in to Azure. Initiating login...${NC}"
    az login
fi

# Validate subscription ID
if [ -z "$SUBSCRIPTION_ID" ]; then
    # List available subscriptions and ask user to select one
    echo -e "${YELLOW}No subscription ID provided. Available subscriptions:${NC}"
    az account list --query "[].{Name:name, SubscriptionId:id}" -o table
    
    echo -e "${YELLOW}Please enter the subscription ID to use:${NC}"
    read -r SUBSCRIPTION_ID
    
    if [ -z "$SUBSCRIPTION_ID" ]; then
        echo -e "${RED}Error: No subscription ID provided.${NC}"
        exit 1
    fi
fi

# Set the subscription
echo "Setting subscription to ${SUBSCRIPTION_ID}..."
az account set --subscription "$SUBSCRIPTION_ID"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to set subscription. Please check the subscription ID and try again.${NC}"
    exit 1
fi

# Set subscription scope
SUBSCRIPTION_SCOPE="/subscriptions/$SUBSCRIPTION_ID"

# Check if the service principal already exists
SP_EXISTS=$(az ad sp list --display-name "$SP_NAME" --query "[].appId" -o tsv)
if [ -n "$SP_EXISTS" ]; then
    echo -e "${YELLOW}Service principal '$SP_NAME' already exists.${NC}"
    echo -e "${YELLOW}Would you like to delete it and create a new one? (y/n)${NC}"
    read -r RESPONSE
    
    if [[ "$RESPONSE" =~ ^[Yy]$ ]]; then
        echo "Deleting existing service principal..."
        az ad sp delete --id "$SP_EXISTS"
    else
        echo -e "${RED}Aborting. Please use a different name for the service principal.${NC}"
        exit 1
    fi
fi

# Calculate expiry date
END_DATE=$(date -d "+$EXPIRY_YEARS years" +%Y-%m-%d)

# Create the service principal with a role assignment
echo "Creating service principal '$SP_NAME' with Contributor role on subscription..."
SP_CREATION=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --role "Contributor" \
    --scopes "$SUBSCRIPTION_SCOPE" \
    --years "$EXPIRY_YEARS" \
    -o json)

# Extract values
APP_ID=$(echo "$SP_CREATION" | jq -r '.appId')
CLIENT_SECRET=$(echo "$SP_CREATION" | jq -r '.password')
TENANT_ID=$(echo "$SP_CREATION" | jq -r '.tenant')

# Wait for the service principal to propagate
echo "Waiting for service principal to propagate..."
sleep 60

echo "Temporarily adding User Access Administrator role to the service principal..."
ROLE_ASSIGNMENT_ID=$(az role assignment create \
    --assignee "$APP_ID" \
    --role "User Access Administrator" \
    --scope "$SUBSCRIPTION_SCOPE" \
    --query id -o tsv)

echo "Role assignment ID: $ROLE_ASSIGNMENT_ID"

# Store the role assignment ID for later removal
echo "TEMP_ROLE_ASSIGNMENT_ID=\"$ROLE_ASSIGNMENT_ID\"" >> "$ENV_FILE"

# Add a cleanup script that can be run after deployment
cat > "cleanup_privileges.sh" << EOF
#!/bin/bash
# This script removes the temporary User Access Administrator role from the service principal

echo "Removing temporary User Access Administrator role..."
source "$ENV_FILE"

if [ -z "\$TEMP_ROLE_ASSIGNMENT_ID" ]; then
  echo "Error: Role assignment ID not found in $ENV_FILE"
  exit 1
fi

az role assignment delete --ids "\$TEMP_ROLE_ASSIGNMENT_ID"
if [ \$? -eq 0 ]; then
  echo "Successfully removed User Access Administrator role"
  # Remove the variable from the ENV_FILE
  sed -i '/TEMP_ROLE_ASSIGNMENT_ID/d' "$ENV_FILE"
else
  echo "Failed to remove the role. Please check and remove it manually."
fi
EOF

chmod +x cleanup_privileges.sh

echo -e "${YELLOW}IMPORTANT: A temporary 'User Access Administrator' role has been assigned.${NC}"
echo -e "${YELLOW}After completing your Terraform deployment, run ./cleanup_privileges.sh to remove this powerful role.${NC}"


# Check if the resource group for Terraform state exists
RG_EXISTS=$(az group list --query "[?name=='$RESOURCE_GROUP'].name" -o tsv)
if [ -z "$RG_EXISTS" ]; then
    echo -e "${YELLOW}Resource group '$RESOURCE_GROUP' does not exist.${NC}"
    echo -e "${YELLOW}Would you like to create it? (y/n)${NC}"
    read -r RESPONSE
    
    if [[ "$RESPONSE" =~ ^[Yy]$ ]]; then
        echo "Please enter the location for the resource group (e.g., eastus):"
        read -r LOCATION
        
        if [ -z "$LOCATION" ]; then
            echo -e "${RED}Error: No location provided.${NC}"
            exit 1
        fi
        
        echo "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
        az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    else
        echo -e "${YELLOW}Skipping resource group creation.${NC}"
    fi
fi

# Create the environment variables file
echo "Creating environment variables file at $ENV_FILE..."
cat > "$ENV_FILE" << EOF
# Azure credentials for Terraform/Terragrunt
# Created on $(date)
# This file contains sensitive information. Do not commit to version control.

export ARM_SUBSCRIPTION_ID="$SUBSCRIPTION_ID"
export ARM_CLIENT_ID="$APP_ID"
export ARM_CLIENT_SECRET="$CLIENT_SECRET"
export ARM_TENANT_ID="$TENANT_ID"

# Harbor credentials - REPLACE THESE WITH REAL VALUES
export HARBOR_ADMIN_PASSWORD="replace-with-secure-password"
export HARBOR_DB_PASSWORD="replace-with-secure-password"
export HARBOR_REDIS_PASSWORD="replace-with-secure-password"

# To use these variables, run:
# source $ENV_FILE
EOF

chmod 600 "$ENV_FILE"

# Print summary
echo -e "${GREEN}Service principal created successfully!${NC}"
echo -e "${GREEN}Details:${NC}"
echo "  Subscription ID: $SUBSCRIPTION_ID"
echo "  Service Principal Name: $SP_NAME"
echo "  Application (Client) ID: $APP_ID"
echo "  Tenant ID: $TENANT_ID"
echo "  Secret expiry: $END_DATE"
echo -e "${YELLOW}The service principal client secret is only shown once and has been saved to $ENV_FILE${NC}"
echo -e "${YELLOW}Please update the Harbor credentials in $ENV_FILE before using it${NC}"
echo
echo "To use these credentials, run:"
echo -e "${GREEN}source $ENV_FILE${NC}"