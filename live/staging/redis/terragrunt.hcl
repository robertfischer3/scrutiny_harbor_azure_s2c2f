# live/staging/redis/terragrunt.hcl

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/redis"
}

dependencies {
  paths = [
    "../networking",
    "../key_vault",
    "../monitoring"
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
  environment = "staging"
  location    = "eastus"
  
  # Network configuration
  vnet_id         = dependency.networking.outputs.vnet_id
  redis_subnet_id = dependency.networking.outputs.redis_subnet_id
  aks_subnet_cidr = dependency.networking.outputs.aks_subnet_cidr
  
  # Redis configuration - more powerful for staging
  redis_capacity = 2
  redis_family   = "C"
  redis_sku      = "Standard"  # Standard tier for staging
  
  # Memory configuration
  maxfrag_memory_reserved = 50
  max_memory_reserved     = 50
  
  # Key Vault and monitoring
  key_vault_id               = dependency.key_vault.outputs.key_vault_id
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
  
  # Redis password (from environment variable)
  redis_password = get_env("HARBOR_REDIS_PASSWORD")
  
  # Tags
  tags = {
    Environment = "Staging"
    Application = "Harbor"
    Compliance  = "S2C2F-Level3"
    ManagedBy   = "Terraform"
  }
}