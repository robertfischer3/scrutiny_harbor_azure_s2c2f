# Terragrunt configuration for resource_group in dev environment

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/resource_group"
}

dependencies {
  paths = [
    # Define dependencies as needed
  ]
}

inputs = {
  # Module-specific inputs
}
