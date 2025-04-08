# modules/key_vault/outputs.tf

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.vault.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.vault.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.vault.vault_uri
}

output "harbor_admin_password_secret_id" {
  description = "ID of the Harbor admin password secret"
  value       = azurerm_key_vault_secret.harbor_admin_password.id
}

output "harbor_db_password_secret_id" {
  description = "ID of the Harbor database password secret"
  value       = azurerm_key_vault_secret.harbor_db_password.id
}

output "harbor_redis_password_secret_id" {
  description = "ID of the Harbor Redis password secret"
  value       = azurerm_key_vault_secret.harbor_redis_password.id
}

output "harbor_tls_cert_secret_id" {
  description = "ID of the Harbor TLS certificate secret"
  value       = var.harbor_tls_cert != null ? azurerm_key_vault_certificate.harbor_tls[0].id : null
}