# Terragrunt configuration for dev environment

include {
  path = find_in_parent_folders()
}

inputs = {
  environment = "dev"
  # Additional environment-specific variables can be defined here
}
