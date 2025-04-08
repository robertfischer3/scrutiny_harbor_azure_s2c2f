# Harbor Operations Manual

This manual provides instructions for operating the Harbor registry infrastructure.

## Deployment

### Prerequisites

- Azure subscription
- Terraform 1.0.0 or later
- Terragrunt 0.35.0 or later
- Azure CLI
- Kubernetes CLI (kubectl)
- Helm 3.x

### Deployment Process

1. Initialize the infrastructure:
   ```bash
   cd scripts
   ./init.sh <environment>  # Where environment is dev, staging, or prod
   ```

2. Apply the infrastructure:
   ```bash
   ./apply.sh <environment>  # Where environment is dev, staging, or prod
   ```

3. To apply a specific component:
   ```bash
   cd live/<environment>/<component>
   terragrunt apply
   ```

4. To apply all components in an environment:
   ```bash
   cd live/<environment>
   terragrunt run-all apply
   ```

## Configuration Management

### Environment Variables

Required environment variables that must be set before deployment:

- `ARM_SUBSCRIPTION_ID`: Azure subscription ID
- `ARM_TENANT_ID`: Azure tenant ID
- `ARM_CLIENT_ID`: Azure service principal client ID
- `ARM_CLIENT_SECRET`: Azure service principal client secret
- `HARBOR_ADMIN_PASSWORD`: Password for Harbor admin user
- `HARBOR_DB_PASSWORD`: Password for Harbor database
- `HARBOR_REDIS_PASSWORD`: Password for Harbor Redis instance

### Terragrunt Configuration

The main Terragrunt configuration is in `terragrunt.hcl` at the root of the repository. Environment-specific configurations are in `live/<environment>/terragrunt.hcl`.

### Environment-Specific Settings

Different environments have different security settings:

- **Dev**: Basic security settings for development
- **Staging**: Enhanced security for testing
- **Production**: Full S2C2F Level 3 compliance

## Access Management

### Azure AD Integration

Harbor is integrated with Azure AD for authentication. To manage access:

1. Add users to the appropriate Azure AD groups:
   - `harbor-<environment>-admins`: For Harbor administrators
   - `harbor-<environment>-developers`: For developers with read/write access
   - `harbor-<environment>-readers`: For read-only access

2. Configure Azure AD roles in the Azure portal:
   ```
   Azure Portal > Azure Active Directory > Enterprise applications > Harbor > Users and groups
   ```

### Role-Based Access Control

Harbor uses RBAC to control access to resources:

| Role | Permissions |
|------|-------------|
| Harbor Administrator | Full access to all Harbor resources |
| Project Administrator | Full access to assigned projects |
| Developer | Push/pull images to assigned projects |
| Guest | Pull images from assigned projects |

### Adding New Users

1. Create the user in Azure AD
2. Add the user to appropriate Azure AD groups
3. Log in to Harbor as an administrator
4. Navigate to Administration > Users
5. Verify the new user appears in the list

## Operational Tasks

### Health Checks

To check the health of Harbor components:

1. Check AKS cluster status:
   ```bash
   az aks show --resource-group harbor-<environment>-aks-rg --name harbor-<environment>-aks --query 'provisioningState' -o tsv
   ```

2. Check Harbor pods:
   ```bash
   kubectl get pods -n harbor
   ```

3. Check Harbor services:
   ```bash
   kubectl get services -n harbor
   ```

4. Check Harbor ingress:
   ```bash
   kubectl get ingress -n harbor
   ```

5. Access Harbor UI:
   ```
   https://<harbor-domain>
   ```

### Backup and Restore

#### Database Backup

Automated backups are configured for the PostgreSQL database:
- Dev: 7-day retention
- Staging: 14-day retention
- Production: 30-day retention

To manually create a database backup:
```bash
az postgres flexible-server backup create --resource-group harbor-<environment>-db-rg --name harbor-<environment>-postgres
```

To restore from a backup:
```bash
az postgres flexible-server restore --resource-group harbor-<environment>-db-rg --name harbor-<environment>-postgres-restored --source-server harbor-<environment>-postgres --restore-point-in-time "2025-04-08T00:00:00Z"
```

#### Registry Data Backup

Registry data is stored in Azure Storage. Point-in-time restore and soft delete are enabled:
- Blob soft delete: 7 days (dev), 14 days (staging), 30 days (production)
- Container soft delete: 7 days (dev), 14 days (staging), 30 days (production)

To restore deleted blobs:
```bash
az storage blob restore --account-name harbor<environment>sa --container-name registry --name <blob-path> --restore-range time-range --start-time "2025-04-01T00:00:00Z" --end-time "2025-04-08T00:00:00Z"
```

### Scaling

#### AKS Scaling

AKS is configured with autoscaling:
- System node pool: 3-5 nodes
- User node pool: 2-5 nodes

To manually scale AKS node pools:
```bash
# Scale system node pool
az aks nodepool scale --resource-group harbor-<environment>-aks-rg --cluster-name harbor-<environment>-aks --name system --node-count 5

# Scale user node pool
az aks nodepool scale --resource-group harbor-<environment>-aks-rg --cluster-name harbor-<environment>-aks --name user --node-count 4
```

#### Harbor Component Scaling

To scale Harbor components:
```bash
# Scale core component
kubectl scale deployment --replicas=3 harbor-core -n harbor

# Scale registry component
kubectl scale deployment --replicas=3 harbor-registry -n harbor
```

### Certificate Management

Harbor uses TLS certificates stored in Azure Key Vault.

To update certificates:
1. Upload new certificate to Key Vault:
   ```bash
   az keyvault certificate import --vault-name harbor-<environment>-kv --name harbor-tls-cert --file cert.pfx
   ```

2. Restart Harbor pods to pick up the new certificate:
   ```bash
   kubectl rollout restart deployment -n harbor
   ```

## Monitoring and Logging

### Monitoring Dashboard

Access the Harbor monitoring dashboard in Azure Portal:
```
Azure Portal > Dashboards > harbor-s2c2f-<environment>
```

### Log Analytics

Access logs in Log Analytics:
```
Azure Portal > Log Analytics workspace > harbor-<environment>-laws > Logs
```

Common queries:

1. Harbor API requests:
   ```
   ContainerLog
   | where LogEntry contains "harbor-core" and LogEntry contains "api"
   | project TimeGenerated, Image, LogEntry
   ```

2. Authentication failures:
   ```
   ContainerLog
   | where LogEntry contains "authentication" and LogEntry contains "failed"
   | project TimeGenerated, Image, LogEntry
   ```

3. Vulnerability scan results:
   ```
   ContainerLog
   | where LogEntry contains "trivy" and LogEntry contains "vulnerability"
   | project TimeGenerated, Image, LogEntry
   ```

### Alerts

Configure additional alerts in Azure Monitor:
```
Azure Portal > Monitor > Alerts > Create > Select scope > harbor-<environment>-laws
```

## Troubleshooting

### Common Issues

#### Harbor UI Inaccessible

1. Check Harbor pods:
   ```bash
   kubectl get pods -n harbor
   ```

2. Check ingress:
   ```bash
   kubectl get ingress -n harbor
   ```

3. Check ingress controller:
   ```bash
   kubectl get pods -n ingress-nginx
   ```

4. Check logs:
   ```bash
   kubectl logs -n harbor deploy/harbor-core
   ```

#### Database Connectivity Issues

1. Check PostgreSQL status:
   ```bash
   az postgres flexible-server show --resource-group harbor-<environment>-db-rg --name harbor-<environment>-postgres --query 'state' -o tsv
   ```

2. Check network connectivity:
   ```bash
   kubectl exec -it -n harbor deploy/harbor-core -- ping harbor-<environment>-postgres.privatelink.postgres.database.azure.com
   ```

3. Check logs:
   ```bash
   kubectl logs -n harbor deploy/harbor-core | grep -i database
   ```

#### Image Push/Pull Failures

1. Check registry pod:
   ```bash
   kubectl get pods -n harbor -l component=registry
   ```

2. Check storage connectivity:
   ```bash
   kubectl exec -it -n harbor deploy/harbor-registry -- ls -la /storage
   ```

3. Check logs:
   ```bash
   kubectl logs -n harbor deploy/harbor-registry
   ```

## Maintenance Procedures

### Upgrading Harbor

1. Update the Harbor chart version in `modules/harbor/variables.tf`:
   ```hcl
   variable "harbor_chart_version" {
     description = "Version of the Harbor Helm chart"
     type        = string
     default     = "1.12.2" # Update this to the desired version
   }
   ```

2. Apply the change:
   ```bash
   cd live/<environment>/harbor
   terragrunt apply
   ```

### Patching AKS

AKS automated upgrades are enabled with the following maintenance window:
- Saturday-Sunday: 22:00-03:00 UTC

To manually upgrade AKS:
```bash
az aks upgrade --resource-group harbor-<environment>-aks-rg --name harbor-<environment>-aks --kubernetes-version 1.28.3
```

### Database Maintenance

Automated maintenance is configured for PostgreSQL with the following window:
- Sunday: 02:00-03:00 UTC

To manually perform maintenance:
```bash
az postgres flexible-server restart --resource-group harbor-<environment>-db-rg --name harbor-<environment>-postgres
```

## Disaster Recovery

### Recovery Point Objective (RPO)

- Production: 1 hour
- Staging: 4 hours
- Development: 24 hours

### Recovery Time Objective (RTO)

- Production: 4 hours
- Staging: 8 hours
- Development: 24 hours

### Disaster Recovery Procedure

1. Assess the damage and identify affected components

2. Restore infrastructure:
   ```bash
   cd scripts
   ./apply.sh <environment>
   ```

3. Restore database from backup:
   ```bash
   az postgres flexible-server restore --resource-group harbor-<environment>-db-rg --name harbor-<environment>-postgres-restored --source-server harbor-<environment>-postgres --restore-point-in-time "2025-04-08T00:00:00Z"
   ```

4. Update database connection in Harbor:
   ```bash
   kubectl edit configmap -n harbor harbor-harbor-core
   ```

5. Restart Harbor components:
   ```bash
   kubectl rollout restart deployment -n harbor
   ```

6. Verify Harbor functionality:
   ```
   https://<harbor-domain>
   ```

## Security Procedures

### Security Patching

1. Monitor security advisories for Harbor and dependencies

2. Apply patches following the change management process

3. Test patches in development and staging before production

### Security Incident Response

1. Isolate affected components:
   ```bash
   kubectl scale deployment --replicas=0 <affected-component> -n harbor
   ```

2. Collect logs for forensic analysis:
   ```bash
   kubectl logs -n harbor deploy/<component> > component-logs.txt
   ```

3. Consult Azure Security Center for recommendations

4. Follow the organization's incident response plan

### Security Compliance Verification

Run the compliance verification script quarterly:
```bash
cd scripts
./verify-compliance.sh <environment>
```

## Reference

### URLs and Endpoints

- Harbor UI: `https://<harbor-domain>`
- Notary: `https://notary.<harbor-domain>`
- API: `https://<harbor-domain>/api/v2.0`

### Helpful Commands

```bash
# Get Harbor admin password from Key Vault
az keyvault secret show --vault-name harbor-<environment>-kv --name harbor-admin-password --query 'value' -o tsv

# Get Harbor database password from Key Vault
az keyvault secret show --vault-name harbor-<environment>-kv --name harbor-db-password --query 'value' -o tsv

# Get AKS credentials
az aks get-credentials --resource-group harbor-<environment>-aks-rg --name harbor-<environment>-aks

# Push an image to Harbor
docker login <harbor-domain>
docker tag myimage:<tag> <harbor-domain>/library/myimage:<tag>
docker push <harbor-domain>/library/myimage:<tag>

# Pull an image from Harbor
docker pull <harbor-domain>/library/myimage:<tag>
```