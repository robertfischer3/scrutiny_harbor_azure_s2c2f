# live/dev/database/terragrunt.hcl

include {
  path = "${find_in_parent_folders("root.hcl")}"
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

inputs = {
  # Basic configuration
  environment      = "dev"
  location         = "eastus"
  
  # Network configuration
  vnet_id          = dependency.networking.outputs.vnet_id
  db_subnet_id     = dependency.networking.outputs.db_subnet_id
  aks_subnet_cidr  = dependency.networking.outputs.aks_subnet_cidr
  
  # PostgreSQL configuration - lightweight for dev
  postgres_version = "14"
  postgres_sku     = "B_Standard_B1ms"  # Basic tier for dev
  postgres_storage_mb = 32768  # 32GB
  postgres_admin_username = "postgres"
  postgres_admin_password = get_env("HARBOR_DB_PASSWORD")
  
  # Basic backup settings for dev
  backup_retention_days = 7
  
  # No encryption key for dev environment to keep it simple
  key_vault_key_id = null
  user_assigned_identity_id = null
  
  # Monitoring
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
  
  # Tags
  tags = {
    Environment = "Development"
    Application = "Harbor"
    ManagedBy   = "Terraform"
  }
}