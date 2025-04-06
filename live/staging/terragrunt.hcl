# Terragrunt configuration for staging environment

include {
  path = find_in_parent_folders()
}

inputs = {
  environment = "staging"
  # Additional environment-specific variables can be defined here
}
