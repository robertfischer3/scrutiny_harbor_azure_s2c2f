# Terragrunt configuration for aks in dev environment

include {
  path = "${find_in_parent_folders("root.hcl")}"
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
