# Terragrunt configuration for networking in dev environment
include {
  path = "${find_in_parent_folders("root.hcl")}"
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
