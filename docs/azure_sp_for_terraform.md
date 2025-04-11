# Azure Service Principal for Terraform/Terragrunt Harbor Deployment

## Architectural Approach

### Overview

This document describes the architectural approach and implementation details for the Azure Service Principal setup script designed for Terraform/Terragrunt Harbor deployment on Azure with S2C2F Level 3 compliance. The script creates the necessary authentication credentials to automate infrastructure deployment while adhering to security best practices.

### Security-First Design

The script follows a security-first design philosophy, implementing several critical security practices:

1. **Time-Limited Credentials**: Service Principal secrets are created with a configurable expiration date (default: 1 year), reducing the risk associated with long-lived credentials.
2. **Least Privilege**: The script sets up the Service Principal with appropriate permissions needed for the deployment, following the principle of least privilege.
3. **Secure Credential Storage**: Generated credentials are stored in a permission-restricted file (600) to prevent unauthorized access.
4. **Input Validation**: User inputs are validated to prevent errors and security issues during the credential creation process.

### Modular Architecture

The script is built with a modular architecture that separates different concerns:

1. **Configuration Management**: Command-line parameters with sensible defaults provide flexibility without compromising usability.
2. **Authentication Flow**: The script handles the full authentication lifecycle, from validating existing Azure CLI login to creating service principals.
3. **Resource Validation**: The script checks for existing resources (service principals, resource groups) to prevent conflicts and offer appropriate remediation options.
4. **Environment Setup**: The script generates the required environment variables file with all necessary credentials.

### Integration with Azure Resource Model

The script is designed to integrate seamlessly with Azure's resource model:

1. **Subscription-Level Scope**: The Service Principal is granted Contributor permissions at the subscription level, allowing it to manage all resources required by the Harbor deployment.
2. **Resource Group Management**: The script supports the creation of a resource group dedicated to Terraform state if one doesn't already exist.
3. **Azure AD Integration**: The script handles Azure Active Directory operations to create and manage the Service Principal.

### Idempotent and User-Friendly

The script is designed with user experience and reliability in mind:

1. **Idempotent Operations**: The script checks for existing resources and offers remediation, making it safe to run multiple times.
2. **Interactive Mode**: When parameters are not provided, the script enters an interactive mode, guiding users through necessary inputs.
3. **Clear Output**: The script provides clear, color-coded output to highlight important information and next steps.
4. **Environment File**: The generated environment file contains all necessary variables, including explanatory comments.

## Instructions

### Prerequisites

Before running the script, ensure you have:

1. Azure CLI installed on your system
2. An Azure account with permissions to create service principals
3. Bash shell environment (Linux, macOS, or Windows with WSL)
4. `jq` command-line tool for JSON processing (usually installable via package managers)

### Installation and Setup

1. **Download the script**

   Save the script as `azure-service-principal-setup.sh` in your project directory.

2. **Make the script executable**

   ```bash
   chmod +x azure-service-principal-setup.sh
   ```

### Running the Script

You can run the script in several ways depending on your preferences:

#### Basic Usage with Defaults

```bash
./azure-service-principal-setup.sh -s YOUR_SUBSCRIPTION_ID
```

This will create a service principal named `harbor-terraform-sp` with Contributor permissions on the specified subscription, and create a `.env` file with the necessary credentials.

#### Full Custom Configuration

```bash
./azure-service-principal-setup.sh \
  --subscription-id YOUR_SUBSCRIPTION_ID \
  --name custom-harbor-sp \
  --resource-group custom-terraform-state \
  --output terraform.env \
  --years 2
```

This will create a service principal with a custom name, associate it with a specific resource group for Terraform state, output credentials to a custom file, and set a 2-year expiration.

#### Interactive Mode

```bash
./azure-service-principal-setup.sh
```

Running the script without parameters will enter interactive mode, which will guide you through providing the necessary information.

### Script Parameters

| Parameter | Short | Description | Default |
|-----------|-------|-------------|---------|
| `--subscription-id` | `-s` | Azure subscription ID | (Required) |
| `--name` | `-n` | Service principal name | `harbor-terraform-sp` |
| `--resource-group` | `-r` | Resource group for Terraform state | `terraform-state-rg` |
| `--output` | `-o` | Output file for environment variables | `.env` |
| `--years` | `-y` | Secret expiry in years | `1` |
| `--help` | `-h` | Display help message | - |

### Using the Generated Credentials

After successfully running the script:

1. **Source the environment file**

   ```bash
   source .env  # or your custom output file
   ```

   This will load the necessary environment variables for Terraform/Terragrunt to authenticate with Azure.

2. **Update Harbor credentials**

   Edit the `.env` file to set secure passwords for:
   
   - `HARBOR_ADMIN_PASSWORD`
   - `HARBOR_DB_PASSWORD`
   - `HARBOR_REDIS_PASSWORD`

3. **Run Terragrunt/Terraform**

   With the environment variables set, you can now run your Terragrunt/Terraform commands:

   ```bash
   cd scripts
   ./init.sh dev      # Initialize dev environment
   ./apply.sh dev     # Apply dev environment
   ```

### Security Considerations

1. **Credential Rotation**

   The service principal credentials are set to expire after the specified period (default: 1 year). Make sure to run the script again before expiration to generate new credentials.

2. **Secure Storage**

   The `.env` file contains sensitive information. Ensure it is:
   - Never committed to version control
   - Stored with restricted permissions (the script sets 600)
   - Deleted when no longer needed

3. **Least Privilege**

   By default, the script assigns Contributor role at the subscription level. For enhanced security in production environments, consider modifying the script to use more restrictive custom roles.

### Troubleshooting

1. **Azure CLI Not Installed**

   If you see `Error: Azure CLI is not installed`, install the Azure CLI according to the [official documentation](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

2. **Authentication Failures**

   If the script fails during Azure authentication, ensure you have the correct permissions in your Azure account to create service principals.

3. **Resource Group Creation Failures**

   If resource group creation fails, verify you have permissions to create resource groups in the selected location.

4. **Service Principal Already Exists**

   If a service principal with the same name already exists, the script will prompt you to delete it or abort. Choose based on whether you're still using that service principal.

5. **Empty Environment Variables After Sourcing**

   If environment variables are empty after sourcing the `.env` file, check for syntax errors in the file. The script should generate a valid file, but manual edits might introduce errors.

## Conclusion

The Azure Service Principal setup script provides a secure, user-friendly way to create and manage the authentication credentials needed for Terraform/Terragrunt to deploy Harbor on Azure with S2C2F Level 3 compliance. By following the architectural principles outlined above and the instructions provided, you can ensure a smooth and secure deployment process.

Remember to follow security best practices when managing the generated credentials, including regular rotation and secure storage.