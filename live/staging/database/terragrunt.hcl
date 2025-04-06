# Terragrunt configuration for database in staging environment

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/database"
}

dependencies {
  paths = [
    # Define dependencies as needed
  ]
}

inputs = {
  # Module-specific inputs
}
