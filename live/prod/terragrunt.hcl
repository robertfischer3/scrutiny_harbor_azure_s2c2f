# Terragrunt configuration for prod environment

include {
  path = find_in_parent_folders()
}

inputs = {
  environment = "prod"
  # Additional environment-specific variables can be defined here
}
