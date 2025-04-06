# Terragrunt configuration for harbor in prod environment

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/harbor"
}

dependencies {
  paths = [
    # Define dependencies as needed
  ]
}

inputs = {
  # Module-specific inputs
}
