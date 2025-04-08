# modules/monitoring/outputs.tf

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.logs.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.logs.name
}

output "log_analytics_workspace_primary_key" {
  description = "Primary shared key for the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.logs.primary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_secondary_key" {
  description = "Secondary shared key for the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.logs.secondary_shared_key
  sensitive   = true
}

output "application_insights_id" {
  description = "ID of the Application Insights"
  value       = azurerm_application_insights.harbor_ai.id
}

output "application_insights_app_id" {
  description = "App ID of the Application Insights"
  value       = azurerm_application_insights.harbor_ai.app_id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation Key for the Application Insights"
  value       = azurerm_application_insights.harbor_ai.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for the Application Insights"
  value       = azurerm_application_insights.harbor_ai.connection_string
  sensitive   = true
}

output "diagnostics_storage_account_id" {
  description = "ID of the Storage Account for diagnostics"
  value       = azurerm_storage_account.diag_storage.id
}

output "diagnostics_storage_account_name" {
  description = "Name of the Storage Account for diagnostics"
  value       = azurerm_storage_account.diag_storage.name
}

output "audit_logs_container_name" {
  description = "Name of the Storage Container for audit logs"
  value       = azurerm_storage_container.audit_logs.name
}

output "critical_action_group_id" {
  description = "ID of the critical alerts Action Group"
  value       = azurerm_monitor_action_group.critical_alerts.id
}

output "critical_action_group_name" {
  description = "Name of the critical alerts Action Group"
  value       = azurerm_monitor_action_group.critical_alerts.name
}

output "monitor_workspace_id" {
  description = "ID of the Azure Monitor Workspace"
  value       = azurerm_monitor_workspace.harbor_monitoring.id
}

output "monitor_workspace_name" {
  description = "Name of the Azure Monitor Workspace"
  value       = azurerm_monitor_workspace.harbor_monitoring.name
}

output "dashboard_id" {
  description = "ID of the Harbor monitoring dashboard"
  value       = var.create_dashboard ? azurerm_portal_dashboard.harbor_dashboard.id : null
}

output "compliance_workbook_id" {
  description = "ID of the S2C2F compliance workbook"
  value       = azurerm_application_insights_workbook.s2c2f_compliance.id
}

output "container_insights_data_collection_rule_id" {
  description = "ID of the Container Insights data collection rule"
  value       = azurerm_monitor_data_collection_rule.container_insights.id
}

output "saved_search_security_events_id" {
  description = "ID of the saved search for security events"
  value       = azurerm_log_analytics_saved_search.security_events.id
}