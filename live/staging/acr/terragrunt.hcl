# Terragrunt configuration for acr in staging environment

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/acr"
}

dependencies {
  paths = [
    # Define dependencies as needed
  ]
}

inputs = {
  # Module-specific inputs
}
