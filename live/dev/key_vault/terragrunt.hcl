# Terragrunt configuration for key_vault in dev environment

include {
  path = "${find_in_parent_folders("root.hcl")}"
}

terraform {
  source = "../../../modules/key_vault"
}

dependencies {
  paths = [
    # Define dependencies as needed
  ]
}

inputs = {
  # Module-specific inputs
}
