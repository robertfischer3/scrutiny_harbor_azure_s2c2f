# Terragrunt configuration for monitoring in dev environment

include {
  path = "${find_in_parent_folders("root.hcl")}"
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
