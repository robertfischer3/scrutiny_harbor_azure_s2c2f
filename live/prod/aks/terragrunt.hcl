# Terragrunt configuration for aks in prod environment

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/aks"
}

dependencies {
  paths = [
    # Define dependencies as needed
  ]
}

inputs = {
  # Module-specific inputs
}
