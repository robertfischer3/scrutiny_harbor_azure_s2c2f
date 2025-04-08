# live/prod/redis/terragrunt.hcl

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
  environment = "prod"
  location    = "eastus"
  
  # Network configuration
  vnet_id         = dependency.networking.outputs.vnet_id
  redis_subnet_id = dependency.networking.outputs.redis_subnet_id
  aks_subnet_cidr = dependency.networking.outputs.aks_subnet_cidr
  
  # Redis configuration - premium for production
  redis_capacity = 2
  redis_family   = "P"  # Premium family for HA
  redis_sku      = "Premium"  # Premium tier for production
  
  # Memory configuration - higher for production workloads
  maxfrag_memory_reserved = 100
  max_memory_reserved     = 100
  
  # Key Vault and monitoring
  key_vault_id               = dependency.key_vault.outputs.key_vault_id
  log_analytics_workspace_id = dependency.monitoring.outputs.log_analytics_workspace_id
  
  # Redis password (from environment variable)
  redis_password = get_env("HARBOR_REDIS_PASSWORD")
  
  # Tags
  tags = {
    Environment = "Production"
    Application = "Harbor"
    Compliance  = "S2C2F-Level3"
    ManagedBy   = "Terraform"
  }
}