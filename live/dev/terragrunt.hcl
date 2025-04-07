# live/dev/terragrunt.hcl (updated)

# Include root terragrunt.hcl
include {
  path = find_in_parent_folders()
}

# Local variables for dev environment
locals {
  
  # These would be populated from environment variables during CI/CD
  harbor_admin_password = get_env("HARBOR_ADMIN_PASSWORD")
  harbor_db_password    = get_env("HARBOR_DB_PASSWORD")
  harbor_redis_password = get_env("HARBOR_REDIS_PASSWORD")
}

inputs = {
  environment            = "dev"
  harbor_admin_password = local.harbor_admin_password
  harbor_db_password    = local.harbor_db_password
  harbor_redis_password = local.harbor_redis_password
  # Other dev environment variables
}