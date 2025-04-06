# Terragrunt configuration for storage in staging environment

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/storage"
}

dependencies {
  paths = [
    # Define dependencies as needed
  ]
}

inputs = {
  # Module-specific inputs
}
