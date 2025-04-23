# Harbor on Azure with S2C2F Level 3 Compliance

This repository contains Infrastructure-as-Code (IaC) to deploy Harbor container registry on Azure with S2C2F Level 3 compliance. The infrastructure is defined using Terraform and orchestrated with Terragrunt.

## Architecture

The deployment follows a secure architecture with the following components:

- **Azure Kubernetes Service (AKS)**: Hosts the Harbor container registry
- **Azure Container Registry (ACR)**: Serves as a backup registry and for initial bootstrapping
- **Azure Database for PostgreSQL**: Provides the database backend for Harbor
- **Azure Cache for Redis**: Handles caching functionality for Harbor
- **Azure Key Vault**: Manages secrets and certificates
- **Azure Storage**: Provides persistent storage for registry artifacts
- **Azure Monitor**: Comprehensive monitoring and logging solution

The infrastructure is deployed across multiple environments (dev, staging, prod) with appropriate security controls for each environment.

## S2C2F Level 3 Compliance

This implementation adheres to S2C2F Level 3 compliance requirements, including:

- Artifact signing enforcement
- Vulnerability scanning
- Network isolation
- RBAC controls
- Comprehensive audit logging
- Secure secrets management

For detailed compliance information, see the [S2C2F Compliance Documentation](docs/security_compliance.md).

## Repository Structure

```
.
├── _env/                  # Environment-specific variables
├── docs/                  # Documentation
├── live/                  # Environment-specific Terragrunt configurations
│   ├── dev/               # Development environment
│   ├── staging/           # Staging environment
│   └── prod/              # Production environment
├── modules/               # Reusable Terraform modules
│   ├── acr/               # Azure Container Registry
│   ├── aks/               # Azure Kubernetes Service
│   ├── database/          # Azure Database for PostgreSQL
│   ├── harbor/            # Harbor deployment
│   ├── key_vault/         # Azure Key Vault
│   ├── monitoring/        # Azure Monitor
│   ├── networking/        # Azure Networking
│   ├── rbac/              # Role-Based Access Control
│   ├── redis/             # Azure Cache for Redis
│   └── storage/           # Azure Storage
├── policies/              # Security policies
├── scripts/               # Utility scripts
└── terragrunt.hcl         # Root Terragrunt configuration
```

## Prerequisites

- Azure subscription
- Terraform >= 1.0.0
- Terragrunt >= 0.35.0
- Azure CLI >= 2.30.0
- Kubernetes CLI (kubectl) >= 1.23.0
- Helm >= 3.8.0

## Getting Started

1. Clone this repository
2. Set up the required environment variables:

```bash
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"

# Harbor credentials for the environment
export HARBOR_ADMIN_PASSWORD="secure-password"
export HARBOR_DB_PASSWORD="secure-password"
export HARBOR_REDIS_PASSWORD="secure-password"
```

3. Initialize the infrastructure:

```bash
cd scripts
./init.sh dev  # For development environment
```

4. Apply the infrastructure:

```bash
./apply.sh dev  # For development environment
```

## Deployment Workflow

1. **Resource Group**: Create the resource group for all resources
2. **Networking**: Set up virtual networks and subnets
3. **Key Vault**: Deploy Key Vault for secrets management
4. **Storage**: Configure Azure Storage accounts
5. **Database**: Deploy Azure Database for PostgreSQL
6. **Redis**: Set up Azure Cache for Redis
7. **ACR**: Deploy Azure Container Registry
8. **AKS**: Set up Azure Kubernetes Service
9. **Monitoring**: Configure Azure Monitor
10. **Harbor**: Deploy Harbor container registry

## Environment-Specific Configurations

Each environment (dev, staging, prod) has specific configurations with increasing security controls:

- **Development**: Basic configuration for development and testing
- **Staging**: Enhanced security controls for pre-production validation
- **Production**: Full S2C2F Level 3 compliance with maximum security controls

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Maintainer

Robert Fischer