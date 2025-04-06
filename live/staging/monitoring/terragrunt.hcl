# Terragrunt configuration for monitoring in staging environment

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/monitoring"
}

dependencies {
  paths = [
    # Define dependencies as needed
  ]
}

inputs = {
  # Module-specific inputs
}
