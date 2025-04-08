# modules/database/outputs.tf

output "postgresql_server_id" {
  description = "ID of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.postgres.id
}

output "postgresql_server_name" {
  description = "Name of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.postgres.name
}

output "postgresql_server_fqdn" {
  description = "FQDN of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "harbor_database_name" {
  description = "Name of the Harbor database"
  value       = azurerm_postgresql_flexible_server_database.harbor_db.name
}

output "postgresql_connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgres://${azurerm_postgresql_flexible_server.postgres.administrator_login}:${azurerm_postgresql_flexible_server.postgres.administrator_password}@${azurerm_postgresql_flexible_server.postgres.fqdn}:5432/${azurerm_postgresql_flexible_server_database.harbor_db.name}"
  sensitive   = true
}