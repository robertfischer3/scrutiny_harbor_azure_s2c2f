# Terragrunt configuration for networking in staging environment

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/networking"
}

dependencies {
  paths = [
    # Define dependencies as needed
  ]
}

inputs = {
  # Module-specific inputs
}
