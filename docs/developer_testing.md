# Harbor S2C2F Development Testing Guide

This guide provides instructions for testing the Harbor container registry deployment with S2C2F Level 3 compliance in a development environment. It is intended for implementers and operators who need to validate the infrastructure and functionality before promoting to higher environments.

## Prerequisites

Before beginning testing, ensure you have the following:

- Azure subscription with Contributor permissions
- Terraform v1.0.0 or later
- Terragrunt v0.35.0 or later
- Azure CLI v2.30.0 or later
- Kubernetes CLI (kubectl) v1.23.0 or later
- Helm v3.8.0 or later
- Docker CLI
- Git
- A terminal or command-line interface

## Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/harbor-azure-s2c2f.git
cd harbor-azure-s2c2f
```

### 2. Configure Azure Authentication

```bash
# Login to Azure
az login

# Set the subscription context
az account set --subscription "Your-Subscription-ID"

# Verify your account
az account show
```

Alternatively, you can set up Service Principal authentication using environment variables:

```bash
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
```

### 3. Set Required Environment Variables

```bash
# Harbor credentials
export HARBOR_ADMIN_PASSWORD="a-secure-password-for-testing"
export HARBOR_DB_PASSWORD="a-secure-db-password-for-testing"
export HARBOR_REDIS_PASSWORD="a-secure-redis-password-for-testing"
```

## Deployment for Testing

### 1. Initialize the Development Environment

```bash
cd scripts
./init.sh dev
```

This script initializes the Terraform state for all components in the dev environment.

### 2. Deploy the Infrastructure

```bash
./apply.sh dev
```

This deploys all infrastructure components in sequence, respecting dependencies.

Alternatively, to deploy components individually for more granular testing:

```bash
cd ../live/dev

# Deploy networking first
cd networking
terragrunt apply

# Then resource group
cd ../resource_group
terragrunt apply

# Then key vault
cd ../key_vault
terragrunt apply

# Continue with remaining components...
```

### 3. Access Deployment Outputs

Retrieve important deployment information:

```bash
cd ../live/dev
terragrunt output
```

## Testing Components

### 1. Verify Azure Resources

#### Verify Network Configuration

```bash
# Check the virtual network
az network vnet show --resource-group harbor-dev-network-rg --name harbor-dev-vnet

# Check subnets
az network vnet subnet list --resource-group harbor-dev-network-rg --vnet-name harbor-dev-vnet
```

#### Verify AKS Cluster

```bash
# Verify AKS cluster status
az aks show --resource-group harbor-dev-aks-rg --name harbor-dev-aks --query provisioningState

# Get AKS credentials
az aks get-credentials --resource-group harbor-dev-aks-rg --name harbor-dev-aks --overwrite-existing

# Check nodes
kubectl get nodes

# Check system pods
kubectl get pods -A
```

#### Verify Azure Container Registry

```bash
# Check ACR status
az acr show --resource-group harbor-dev-acr-rg --name harbordevacr --query provisioningState

# List repositories (should be empty initially)
az acr repository list --resource-group harbor-dev-acr-rg --name harbordevacr
```

#### Verify Database

```bash
# Check PostgreSQL status
az postgres flexible-server show --resource-group harbor-dev-db-rg --name harbor-dev-postgres --query state
```

#### Verify Key Vault

```bash
# Check Key Vault
az keyvault show --resource-group harbor-dev-kv-rg --name harbor-dev-kv

# List secrets (names only)
az keyvault secret list --vault-name harbor-dev-kv --query "[].name"
```

### 2. Verify Harbor Deployment

#### Check Harbor Pods

```bash
# Check Harbor namespace
kubectl get namespace harbor

# Check Harbor pods
kubectl get pods -n harbor

# Check Harbor services
kubectl get svc -n harbor

# Check Harbor ingress
kubectl get ingress -n harbor
```

#### Get Harbor URL and Credentials

```bash
# Get Harbor URL (should be in the ingress resource)
HARBOR_URL=$(kubectl get ingress -n harbor -o jsonpath='{.items[0].spec.rules[0].host}')
echo "Harbor URL: https://$HARBOR_URL"

# Get admin password from Key Vault
HARBOR_ADMIN_PASSWORD=$(az keyvault secret show --vault-name harbor-dev-kv --name harbor-admin-password --query 'value' -o tsv)
echo "Admin Password: $HARBOR_ADMIN_PASSWORD"
```

### 3. Test Harbor Functionality

#### Access Harbor UI

1. Open a browser and navigate to `https://<HARBOR_URL>`
2. Log in with:
   - Username: `admin`
   - Password: The value of `$HARBOR_ADMIN_PASSWORD`

#### Create a Test Project

1. In the Harbor UI, click on "New Project"
2. Name it "test-project"
3. Set it as Public for testing purposes
4. Click "OK"

#### Push a Test Image

```bash
# Login to Docker
docker login https://$HARBOR_URL -u admin -p $HARBOR_ADMIN_PASSWORD

# Pull a test image
docker pull nginx:latest

# Tag for Harbor
docker tag nginx:latest $HARBOR_URL/test-project/nginx:v1

# Push to Harbor
docker push $HARBOR_URL/test-project/nginx:v1
```

#### Verify Image in Harbor UI

1. Navigate to "test-project" in the Harbor UI
2. Verify the nginx:v1 image appears
3. Click on the image to view details

### 4. Test Security Features

#### Test Vulnerability Scanning

1. In the Harbor UI, navigate to your test-project
2. Find the nginx image and click on it
3. Click on the "Scan" button
4. Wait for the scan to complete
5. Review the vulnerabilities found

#### Test RBAC

Create a test user and test access controls:

```bash
# Create a test user via API
curl -X POST -H "Content-Type: application/json" -d '{"username":"testuser","email":"test@example.com","realname":"Test User","password":"Test@1234"}' -u "admin:$HARBOR_ADMIN_PASSWORD" "https://$HARBOR_URL/api/v2.0/users"

# Or create a user through the Harbor UI and assign limited permissions to test-project
```

Now test accessing from a different context:

```bash
# Log out from admin in UI
# Log in as testuser with password Test@1234
# Verify access limitations based on assigned permissions
```

#### Test Image Signing (if enabled in dev)

```bash
# Install Notary client if not already installed
# Configure Docker content trust
export DOCKER_CONTENT_TRUST=1
export DOCKER_CONTENT_TRUST_SERVER=https://notary.$HARBOR_URL

# Sign and push an image
docker tag nginx:latest $HARBOR_URL/test-project/nginx:signed
docker push $HARBOR_URL/test-project/nginx:signed
```

### 5. Test Monitoring and Logging

#### Verify Log Collection

```bash
# Check that logs are being collected in Log Analytics
az monitor log-analytics query --workspace-name harbor-dev-laws --analytics-query "ContainerLog | where LogEntry contains 'harbor' | limit 10" -o table
```

#### Check Monitoring Dashboard

1. Navigate to the Azure Portal
2. Go to Dashboards
3. Find and open the "harbor-s2c2f-dev" dashboard
4. Verify metrics and visualizations are populating

## Testing Other Features

### Test Storage Integration

1. Verify Harbor is using Azure Storage by pushing a large image
2. Check the Azure Storage Account to see the blob content

```bash
# List storage containers
az storage container list --account-name harbordevsa --query "[].name"

# List blobs in registry container (requires storage account key)
STORAGE_KEY=$(az storage account keys list --account-name harbordevsa --query "[0].value" -o tsv)
az storage blob list --container-name registry --account-name harbordevsa --account-key $STORAGE_KEY
```

### Test High Availability (if configured in dev)

If you've configured HA features in dev:

```bash
# Scale the Harbor core deployment
kubectl scale deployment harbor-core -n harbor --replicas=2

# Verify replicas are running
kubectl get pods -n harbor | grep harbor-core
```

## Troubleshooting

### Common Issues

#### Harbor UI Not Accessible

```bash
# Check ingress status
kubectl describe ingress -n harbor

# Check ingress controller pods
kubectl get pods -n ingress-nginx

# Check Harbor core pod logs
kubectl logs -n harbor deploy/harbor-core

# Check Harbor portal pod logs
kubectl logs -n harbor deploy/harbor-portal
```

#### Image Push Failure

```bash
# Check registry pod logs
kubectl logs -n harbor deploy/harbor-registry

# Check storage connectivity
kubectl exec -n harbor deploy/harbor-registry -- ls -la /storage

# Verify network policies
kubectl get networkpolicy -n harbor
```

#### Database Connectivity Issues

```bash
# Check core pod logs for database errors
kubectl logs -n harbor deploy/harbor-core | grep -i database

# Verify database settings in ConfigMap
kubectl get configmap -n harbor harbor-harbor-core -o yaml
```

## Cleanup

When testing is complete, you can clean up the environment:

```bash
cd scripts
./destroy.sh dev
```

Or to destroy specific components:

```bash
cd ../live/dev/harbor
terragrunt destroy

# Continue with other components in reverse order of creation
```

## Next Steps

After successfully testing in the development environment:

1. Document any issues found and fixes applied
2. Update configurations as needed based on testing results
3. Initiate deployment to the staging environment
4. Conduct more rigorous compliance testing in staging
5. Prepare for production deployment

## Reference

### Important File Locations

- Terraform modules: `./modules/`
- Environment configurations: `./live/dev/`
- Shared Terragrunt configuration: `./terragrunt.hcl`
- Scripts: `./scripts/`

### Command Reference

| Task | Command |
|------|---------|
| Initialize environment | `./scripts/init.sh dev` |
| Apply changes | `./scripts/apply.sh dev` |
| Destroy environment | `./scripts/destroy.sh dev` |
| Get AKS credentials | `az aks get-credentials --resource-group harbor-dev-aks-rg --name harbor-dev-aks` |
| Check Harbor pods | `kubectl get pods -n harbor` |
| Get admin password | `az keyvault secret show --vault-name harbor-dev-kv --name harbor-admin-password --query 'value' -o tsv` |

### Harbor API Reference

For automated testing, you may want to use the Harbor API:

- API Base URL: `https://<HARBOR_URL>/api/v2.0`
- [Harbor API Documentation](https://goharbor.io/docs/2.4.0/build-customize-contribute/configure-swagger-docs/)
- Authentication: HTTP Basic Auth with admin credentials or created API keys