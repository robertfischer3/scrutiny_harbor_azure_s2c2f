# Terragrunt configuration for redis in staging environment

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/redis"
}

dependencies {
  paths = [
    # Define dependencies as needed
  ]
}

inputs = {
  # Module-specific inputs
}
