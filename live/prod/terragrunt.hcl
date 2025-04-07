# live/prod/terragrunt.hcl (updated)

# Include root terragrunt.hcl
include {
  path = find_in_parent_folders()
}

# Local variables for prod environment
locals {
  # For prod, NEVER use defaults
  # All secrets must be provided via environment variables
  # We'll validate that the environment variables are set
  harbor_admin_password = get_env("HARBOR_ADMIN_PASSWORD")
  harbor_db_password    = get_env("HARBOR_DB_PASSWORD")
  harbor_redis_password = get_env("HARBOR_REDIS_PASSWORD")
}

# Verify required secrets are provided
terraform {
  before_hook "check_secrets" {
    commands     = ["apply", "plan", "destroy"]
    execute      = [
      "/bin/sh", 
      "-c", 
      "if [ -z \"$HARBOR_ADMIN_PASSWORD\" ] || [ -z \"$HARBOR_DB_PASSWORD\" ] || [ -z \"$HARBOR_REDIS_PASSWORD\" ]; then echo 'ERROR: Required secrets not provided via environment variables'; exit 1; fi"
    ]
  }
}

inputs = {
  environment            = "prod"
  harbor_admin_password = local.harbor_admin_password
  harbor_db_password    = local.harbor_db_password
  harbor_redis_password = local.harbor_redis_password
  
  # Production-specific settings
  key_vault_network_acls = {
    default_action        = "Deny"
    bypass                = "AzureServices"
    ip_rules              = []  # Will be populated during deployment
    virtual_network_rules = []  # Will reference the AKS subnet
  }
  
  # Other prod environment variables
}