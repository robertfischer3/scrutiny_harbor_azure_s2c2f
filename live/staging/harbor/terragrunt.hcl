# live/staging/database/terragrunt.hcl

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/database"
}

dependencies {
  paths = [
    "../networking",
    "../key_vault"
  ]
}

dependency "networking" {
  config_path = "../networking"
}

dependency "key_vault" {
  config_path = "../key_vault"
}

dependency "monitoring" {
  config_path = "../monitoring"
}

# Generate an Azure AD identity for database in staging
terraform {
  before_hook "create_identity" {
    commands = ["apply", "plan"]
    execute  = [
      "az", "identity", "create",
      "--name", "harbor-staging-db-identity",
      "--resource-group", "harbor-staging-db-rg",
      "--location", "eastus",
      "--query", "id",
      "--output", "tsv"
    ]
    run_on_error = false
  }
}

inputs = {
  # Basic configuration
  environment      = "staging"
  location         = "eastus"
  
  # Network configuration
  vnet_id          = dependency.networking.outputs.vnet_id
  db_subnet_id     = dependency.networking.outputs.db_subnet_id
  aks_subnet_cidr  = dependency.networking.outputs.aks_subnet_cidr
  
  # PostgreSQL configuration - medium tier for staging
  postgres_version = "14"
  postgres_sku     = "GP_Standard_D2s_v3"  # General purpose for staging
  postgres_storage_mb = 32768  # 32GB
  postgres_admin_username = "postgres"
  postgres_admin_password = get_env("HARBOR_DB_PASSWORD")
  
  # Medium backup settings for staging
  backup_retention_days = 14
  
  # Encryption configuration for staging (S2C2F compliance)
  key_vault_key_id = dependency.key_vault.outputs.database_encryption_key_id
  user_assigned_identity_id = "harbor-staging-db-identity"
  
  # Monitoring
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
  
  # Tags
  tags = {
    Environment = "Staging"
    Application = "Harbor"
    Compliance  = "S2C2F-Level3"
    ManagedBy   = "Terraform"
  }
}