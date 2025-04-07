# modules/rbac/main.tf

# Create Azure AD group for AKS admins
resource "azuread_group" "aks_admins" {
  display_name     = "${var.prefix}-${var.environment}-aks-admins"
  security_enabled = true
}

# Create Azure AD group for Harbor admins
resource "azuread_group" "harbor_admins" {
  display_name     = "${var.prefix}-${var.environment}-harbor-admins"
  security_enabled = true
}

# Create Azure AD group for Harbor developers (read-only)
resource "azuread_group" "harbor_developers" {
  display_name     = "${var.prefix}-${var.environment}-harbor-developers"
  security_enabled = true
}

# Create a service principal for Harbor
resource "azuread_application" "harbor_sp" {
  display_name = "${var.prefix}-${var.environment}-harbor-sp"
}

resource "azuread_service_principal" "harbor_sp" {
  application_id = azuread_application.harbor_sp.application_id
}

resource "azuread_service_principal_password" "harbor_sp_password" {
  service_principal_id = azuread_service_principal.harbor_sp.id
  end_date_relative    = "8760h" # 1 year
}

# Role assignments - assign AKS admin role to the AKS admins group
resource "azurerm_role_assignment" "aks_admin_role" {
  scope                = var.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = azuread_group.aks_admins.id
}

# Role assignments - assign ACR Pull role to the Harbor service principal
resource "azurerm_role_assignment" "harbor_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azuread_service_principal.harbor_sp.id
}

# Role assignments - assign ACR Push role to the Harbor service principal
resource "azurerm_role_assignment" "harbor_acr_push" {
  scope                = var.acr_id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.harbor_sp.id
}

# Store service principal credentials in Key Vault
resource "azurerm_key_vault_secret" "harbor_sp_id" {
  name         = "harbor-sp-id"
  value        = azuread_service_principal.harbor_sp.application_id
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "harbor_sp_secret" {
  name         = "harbor-sp-secret"
  value        = azuread_service_principal_password.harbor_sp_password.value
  key_vault_id = var.key_vault_id
}