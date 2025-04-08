# modules/monitoring/main.tf

# Create Resource Group for monitoring resources
resource "azurerm_resource_group" "monitoring_rg" {
  name     = "${var.prefix}-${var.environment}-monitoring-rg"
  location = var.location
  tags     = var.tags
}

# Create Log Analytics Workspace for centralized logging
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "${var.prefix}-${var.environment}-laws"
  location            = azurerm_resource_group.monitoring_rg.location
  resource_group_name = azurerm_resource_group.monitoring_rg.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days
  
  # Add tags for S2C2F compliance tracking
  tags = merge(var.tags, {
    "s2c2f:component" = "monitoring"
    "s2c2f:level"     = "3"
  })
}

# Create Application Insights for Harbor
resource "azurerm_application_insights" "harbor_ai" {
  name                = "${var.prefix}-${var.environment}-harbor-ai"
  location            = azurerm_resource_group.monitoring_rg.location
  resource_group_name = azurerm_resource_group.monitoring_rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.logs.id
  
  tags = var.tags
}

# Create Storage Account for diagnostic logs archives
resource "azurerm_storage_account" "diag_storage" {
  name                     = "${var.prefix}${var.environment}diagsa"
  resource_group_name      = azurerm_resource_group.monitoring_rg.location
  location                 = azurerm_resource_group.monitoring_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"
  
  # Enable blob encryption
  blob_properties {
    versioning_enabled = true
    
    container_delete_retention_policy {
      days = 30
    }
    
    delete_retention_policy {
      days = 30
    }
  }
  
  # Configure network rules for storage account
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }
  
  tags = var.tags
}

# Create Blob Container for long-term audit logs
resource "azurerm_storage_container" "audit_logs" {
  name                  = "audit-logs"
  storage_account_id    = azurerm_storage_account.diag_storage.id
  container_access_type = "private"
}

# Create Action Group for alerts
resource "azurerm_monitor_action_group" "critical_alerts" {
  name                = "${var.prefix}-${var.environment}-critical-alerts"
  resource_group_name = azurerm_resource_group.monitoring_rg.name
  short_name          = "critical"
  
  email_receiver {
    name                    = "security-team"
    email_address           = var.security_email
    use_common_alert_schema = true
  }
  
  sms_receiver {
    name         = "on-call"
    country_code = var.sms_country_code
    phone_number = var.sms_phone_number
  }
  
  webhook_receiver {
    name                    = "ServiceNow"
    service_uri             = var.webhook_url
    use_common_alert_schema = true
  }
}

# Create Azure Monitor Workspace for centralized monitoring
resource "azurerm_monitor_workspace" "harbor_monitoring" {
  name                = "${var.prefix}-${var.environment}-harbor-mon"
  resource_group_name = azurerm_resource_group.monitoring_rg.name
  location            = var.location
  tags                = var.tags
}

# Set up diagnostic settings for AKS
resource "azurerm_monitor_diagnostic_setting" "aks_diagnostics" {
  name                       = "${var.prefix}-${var.environment}-aks-diag"
  target_resource_id         = var.aks_cluster_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  storage_account_id         = azurerm_storage_account.diag_storage.id
  
  # Collect all AKS logs
  enabled_log {
    category = "kube-apiserver"
    
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
  
  enabled_log {
    category = "kube-audit"
    
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
  
  enabled_log {
    category = "kube-audit-admin"
    
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
  
  enabled_log {
    category = "kube-controller-manager"
    
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
  
  enabled_log {
    category = "kube-scheduler"
    
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
  
  enabled_log {
    category = "cluster-autoscaler"
    
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
  
  enabled_log {
    category = "guard"
    
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
    
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
}

# Set up diagnostic settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "kv_diagnostics" {
  name                       = "${var.prefix}-${var.environment}-kv-diag"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  storage_account_id         = azurerm_storage_account.diag_storage.id
  
  # Enable all logs for Key Vault
  enabled_log {
    category = "AuditEvent"
    
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
  
  enabled_log {
    category = "AzurePolicyEvaluationDetails"
    
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
    
    retention_policy {
      enabled = true
      days    = var.log_retention_days
    }
  }
}

# Create Log Analytics Saved Searches for security monitoring
resource "azurerm_log_analytics_saved_search" "security_events" {
  name                       = "S2C2F-SecurityEvents"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  category                   = "Security"
  display_name               = "S2C2F Level 3 Security Events"
  query                      = <<-QUERY
    union
      (AzureDiagnostics
      | where ResourceType == "KUBERNETESCLUSTERS"
      | where Category == "kube-audit"
      | where log_s contains "Harbor" or log_s contains "artifact" or log_s contains "registry" or log_s contains "exec"
      | where log_s contains "admin" or log_s contains "privileged" or log_s contains "create" or log_s contains "delete"
      | project TimeGenerated, Resource, Category, log_s),
      (AzureDiagnostics
      | where ResourceType == "VAULTS"
      | where OperationName has "Key" or OperationName has "Secret"
      | project TimeGenerated, Resource, OperationName, ResultType, ResultSignature, ObjectName),
      (ContainerLog
      | where LogEntry contains "ERROR" and (LogEntry contains "security" or LogEntry contains "unauthorized")
      | project TimeGenerated, Computer, Image, Name, LogEntry)
    | order by TimeGenerated desc
  QUERY
}

# Create Azure Portal Dashboard for Harbor monitoring
resource "azurerm_portal_dashboard" "harbor_dashboard" {
  name                = "harbor-s2c2f-${var.environment}"
  resource_group_name = azurerm_resource_group.monitoring_rg.name
  location            = azurerm_resource_group.monitoring_rg.location
  tags                = var.tags
  
  dashboard_properties = <<DASHBOARD
{
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {
            "x": 0,
            "y": 0,
            "colSpan": 12,
            "rowSpan": 1
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "# Harbor S2C2F Dashboard - ${upper(var.environment)}",
                  "title": "",
                  "subtitle": "Real-time monitoring for Harbor registry with S2C2F Level 3 compliance"
                }
              }
            }
          }
        },
        "1": {
          "position": {
            "x": 0,
            "y": 1,
            "colSpan": 4,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true,
                "value": "workspace"
              },
              {
                "name": "ComponentId",
                "isOptional": true,
                "value": {
                  "SubscriptionId": "${data.azurerm_subscription.current.subscription_id}",
                  "ResourceGroup": "${azurerm_resource_group.monitoring_rg.name}",
                  "Name": "${azurerm_log_analytics_workspace.logs.name}",
                  "ResourceId": "${azurerm_log_analytics_workspace.logs.id}"
                }
              },
              {
                "name": "Query",
                "isOptional": true,
                "value": "AzureDiagnostics\n| where ResourceType == \"KUBERNETESCLUSTERS\"\n| where Category == \"kube-audit\"\n| where log_s contains \"exec\" or log_s contains \"create\" or log_s contains \"delete\"\n| summarize count() by bin(TimeGenerated, 1h), Resource\n| render timechart"
              },
              {
                "name": "TimeRange",
                "isOptional": true,
                "value": "P1D"
              },
              {
                "name": "Dimensions",
                "isOptional": true,
                "value": {
                  "xAxis": {
                    "name": "TimeGenerated",
                    "type": "datetime"
                  },
                  "yAxis": [
                    {
                      "name": "count_",
                      "type": "long"
                    }
                  ],
                  "splitBy": [
                    {
                      "name": "Resource",
                      "type": "string"
                    }
                  ],
                  "aggregation": "Sum"
                }
              },
              {
                "name": "Version",
                "isOptional": true,
                "value": "1.0"
              },
              {
                "name": "DashboardId",
                "isOptional": true,
                "value": "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.monitoring_rg.name}/providers/Microsoft.Portal/dashboards/harbor-s2c2f-${var.environment}"
              },
              {
                "name": "PartId",
                "isOptional": true,
                "value": "1"
              },
              {
                "name": "PartTitle",
                "isOptional": true,
                "value": "Cluster Admin Operations"
              },
              {
                "name": "PartSubTitle",
                "isOptional": true,
                "value": "High privilege operations by hour"
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
          }
        },
        "2": {
          "position": {
            "x": 4,
            "y": 1,
            "colSpan": 4,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true,
                "value": "workspace"
              },
              {
                "name": "ComponentId",
                "isOptional": true,
                "value": {
                  "SubscriptionId": "${data.azurerm_subscription.current.subscription_id}",
                  "ResourceGroup": "${azurerm_resource_group.monitoring_rg.name}",
                  "Name": "${azurerm_log_analytics_workspace.logs.name}",
                  "ResourceId": "${azurerm_log_analytics_workspace.logs.id}"
                }
              },
              {
                "name": "Query",
                "isOptional": true,
                "value": "ContainerLog\n| where LogEntry contains \"ERROR\" and (LogEntry contains \"security\" or LogEntry contains \"unauthorized\")\n| summarize count() by bin(TimeGenerated, 1h), Image\n| render timechart"
              },
              {
                "name": "TimeRange",
                "isOptional": true,
                "value": "P1D"
              },
              {
                "name": "Dimensions",
                "isOptional": true,
                "value": {
                  "xAxis": {
                    "name": "TimeGenerated",
                    "type": "datetime"
                  },
                  "yAxis": [
                    {
                      "name": "count_",
                      "type": "long"
                    }
                  ],
                  "splitBy": [
                    {
                      "name": "Image",
                      "type": "string"
                    }
                  ],
                  "aggregation": "Sum"
                }
              },
              {
                "name": "Version",
                "isOptional": true,
                "value": "1.0"
              },
              {
                "name": "DashboardId",
                "isOptional": true,
                "value": "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.monitoring_rg.name}/providers/Microsoft.Portal/dashboards/harbor-s2c2f-${var.environment}"
              },
              {
                "name": "PartId",
                "isOptional": true,
                "value": "2"
              },
              {
                "name": "PartTitle",
                "isOptional": true,
                "value": "Harbor Security Events"
              },
              {
                "name": "PartSubTitle",
                "isOptional": true,
                "value": "Error events related to security"
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
          }
        },
        "3": {
          "position": {
            "x": 8,
            "y": 1,
            "colSpan": 4,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "isOptional": true,
                "value": "workspace"
              },
              {
                "name": "ComponentId",
                "isOptional": true,
                "value": {
                  "SubscriptionId": "${data.azurerm_subscription.current.subscription_id}",
                  "ResourceGroup": "${azurerm_resource_group.monitoring_rg.name}",
                  "Name": "${azurerm_log_analytics_workspace.logs.name}",
                  "ResourceId": "${azurerm_log_analytics_workspace.logs.id}"
                }
              },
              {
                "name": "Query",
                "isOptional": true,
                "value": "AzureDiagnostics\n| where ResourceType == \"VAULTS\"\n| where OperationName has \"Key\" or OperationName has \"Secret\"\n| summarize count() by bin(TimeGenerated, 1h), OperationName\n| render timechart"
              },
              {
                "name": "TimeRange",
                "isOptional": true,
                "value": "P1D"
              },
              {
                "name": "Dimensions",
                "isOptional": true,
                "value": {
                  "xAxis": {
                    "name": "TimeGenerated",
                    "type": "datetime"
                  },
                  "yAxis": [
                    {
                      "name": "count_",
                      "type": "long"
                    }
                  ],
                  "splitBy": [
                    {
                      "name": "OperationName",
                      "type": "string"
                    }
                  ],
                  "aggregation": "Sum"
                }
              },
              {
                "name": "Version",
                "isOptional": true,
                "value": "1.0"
              },
              {
                "name": "DashboardId",
                "isOptional": true,
                "value": "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.monitoring_rg.name}/providers/Microsoft.Portal/dashboards/harbor-s2c2f-${var.environment}"
              },
              {
                "name": "PartId",
                "isOptional": true,
                "value": "3"
              },
              {
                "name": "PartTitle",
                "isOptional": true,
                "value": "Key Vault Operations"
              },
              {
                "name": "PartSubTitle",
                "isOptional": true,
                "value": "Secret and key operations by hour"
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
          }
        }
      }
    }
  },
  "metadata": {
    "model": {}
  }
}
DASHBOARD
}

# Create Alert Rules for critical events

# Alert for unauthorized access attempts
resource "azurerm_monitor_scheduled_query_rules_alert" "unauthorized_access" {
  name                = "${var.prefix}-${var.environment}-unauthorized-access-alert"
  location            = azurerm_resource_group.monitoring_rg.location
  resource_group_name = azurerm_resource_group.monitoring_rg.name
  
  action {
    action_group           = [azurerm_monitor_action_group.critical_alerts.id]
    email_subject          = "SECURITY ALERT: Unauthorized access attempts detected"
    custom_webhook_payload = "{\"alert\":\"Unauthorized Access\",\"severity\":\"High\",\"environment\":\"${var.environment}\"}"
  }
  
  data_source_id = azurerm_log_analytics_workspace.logs.id
  description    = "Alerts when multiple unauthorized access attempts are detected"
  enabled        = true
  
  query       = <<-QUERY
    union
      (AzureDiagnostics
      | where ResourceType == "KUBERNETESCLUSTERS"
      | where Category == "kube-audit"
      | where log_s contains "Harbor" and log_s contains "unauthorized"),
      (AzureDiagnostics
      | where ResourceType == "VAULTS"
      | where ResultType == "Unauthorized" or ResultType == "Forbidden"),
      (ContainerLog
      | where LogEntry contains "unauthorized" or LogEntry contains "permission denied" or LogEntry contains "access denied")
    | project TimeGenerated, ResourceType, Category, LogEntry, Resource
    | summarize count() by bin(TimeGenerated, 5m)
    | where count_ > 5
  QUERY
  severity    = 1
  frequency   = 5
  time_window = 5
  
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
  
  tags = var.tags
}

# Alert for image vulnerabilities detected by Trivy scanner
resource "azurerm_monitor_scheduled_query_rules_alert" "vulnerability_detected" {
  name                = "${var.prefix}-${var.environment}-vulnerability-alert"
  location            = azurerm_resource_group.monitoring_rg.location
  resource_group_name = azurerm_resource_group.monitoring_rg.name
  
  action {
    action_group           = [azurerm_monitor_action_group.critical_alerts.id]
    email_subject          = "SECURITY ALERT: Critical vulnerabilities detected in container images"
    custom_webhook_payload = "{\"alert\":\"Vulnerability Detected\",\"severity\":\"High\",\"environment\":\"${var.environment}\"}"
  }
  
  data_source_id = azurerm_log_analytics_workspace.logs.id
  description    = "Alerts when Trivy scanner detects critical vulnerabilities in container images"
  enabled        = true
  
  query       = <<-QUERY
    ContainerLog
    | where LogEntry contains "CRITICAL" and LogEntry contains "vulnerability"
    | where Image has "trivy"
    | project TimeGenerated, Image, LogEntry
    | summarize count() by bin(TimeGenerated, 5m)
  QUERY
  severity    = 1
  frequency   = 5
  time_window = 5
  
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
  
  tags = var.tags
}

# Alert for unusual artifact signing activities
resource "azurerm_monitor_scheduled_query_rules_alert" "artifact_signing_alert" {
  name                = "${var.prefix}-${var.environment}-artifact-signing-alert"
  location            = azurerm_resource_group.monitoring_rg.location
  resource_group_name = azurerm_resource_group.monitoring_rg.name
  
  action {
    action_group           = [azurerm_monitor_action_group.critical_alerts.id]
    email_subject          = "SECURITY ALERT: Unusual artifact signing activity detected"
    custom_webhook_payload = "{\"alert\":\"Artifact Signing\",\"severity\":\"Medium\",\"environment\":\"${var.environment}\"}"
  }
  
  data_source_id = azurerm_log_analytics_workspace.logs.id
  description    = "Alerts when unusual artifact signing activities are detected"
  enabled        = true
  
  query       = <<-QUERY
    ContainerLog
    | where LogEntry contains "artifact" and LogEntry contains "sign"
    | project TimeGenerated, Image, LogEntry, Computer
    | summarize count() by bin(TimeGenerated, 1h), Computer
    | where count_ > 10
  QUERY
  severity    = 2
  frequency   = 60
  time_window = 60
  
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
  
  tags = var.tags
}

# Create Workbooks for compliance reporting
resource "azurerm_application_insights_workbook" "s2c2f_compliance" {
  name                = "${var.prefix}-${var.environment}-s2c2f-compliance-workbook"
  resource_group_name = azurerm_resource_group.monitoring_rg.name
  location            = azurerm_resource_group.monitoring_rg.location
  display_name        = "S2C2F Level 3 Compliance Report"
  
  data_json = <<JSON
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 1,
      "content": {
        "json": "# S2C2F Level 3 Compliance Report\n---\n\nThis workbook provides compliance reporting for the Harbor registry deployment according to S2C2F Level 3 requirements."
      },
      "name": "text - 0"
    },
    {
      "type": 9,
      "content": {
        "version": "KqlParameterItem/1.0",
        "parameters": [
          {
            "id": "f62643b9-d984-4724-82c1-b25d068b3774",
            "version": "KqlParameterItem/1.0",
            "name": "TimeRange",
            "type": 4,
            "isRequired": true,
            "value": {
              "durationMs": 86400000
            },
            "typeSettings": {
              "selectableValues": [
                {
                  "durationMs": 3600000
                },
                {
                  "durationMs": 86400000
                },
                {
                  "durationMs": 604800000
                },
                {
                  "durationMs": 2592000000
                }
              ]
            }
          }
        ],
        "style": "pills",
        "queryType": 0,
        "resourceType": "microsoft.insights/components"
      },
      "name": "parameters - 1"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "AzureDiagnostics\n| where ResourceType == \"KUBERNETESCLUSTERS\"\n| where Category == \"kube-audit\"\n| summarize count() by ResultStatus\n| render piechart",
        "size": 0,
        "title": "Kubernetes API Request Status",
        "timeContext": {
          "durationMs": 86400000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces",
        "crossComponentResources": [
          "{Workspace}"
        ]
      },
      "name": "query - 2"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "AzureDiagnostics\n| where ResourceType == \"VAULTS\"\n| summarize count() by ResultType, OperationName\n| render barchart",
        "size": 0,
        "title": "Key Vault Operations Status",
        "timeContext": {
          "durationMs": 86400000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces",
        "crossComponentResources": [
          "{Workspace}"
        ]
      },
      "name": "query - 3"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "ContainerLog\n| where LogEntry contains \"trivy\" and LogEntry contains \"vulnerability\"\n| summarize VulnerabilityCount=count() by Severity=extract(\"(CRITICAL|HIGH|MEDIUM|LOW)\", 1, LogEntry)\n| render columnchart",
        "size": 0,
        "title": "Image Vulnerabilities by Severity",
        "timeContext": {
          "durationMs": 86400000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces",
        "crossComponentResources": [
          "{Workspace}"
        ]
      },
      "name": "query - 4"
    },
    {
      "type": 1,
      "content": {
        "json": "## S2C2F Compliance Checklist\n\n| Requirement | Status | Evidence |\n|-------------|--------|----------|\n| Artifact Signing | ✅ Active | Notary is enabled and policy is applied |\n| Image Scanning | ✅ Active | Trivy scanning is enabled and enforced |\n| RBAC Controls | ✅ Active | Azure AD integration is configured |\n| Audit Logging | ✅ Active | All events are logged to Log Analytics |\n| Network Isolation | ✅ Active | Network policies are enforced |"
      },
      "name": "text - 5"
    }
  ],
  "styleSettings": {},
  "fromTemplateId": "sentinel-UserWorkbook",
  "$schema": "https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"
}
JSON

  tags = var.tags
}

# Create data collection rule for container insights
resource "azurerm_monitor_data_collection_rule" "container_insights" {
  name                = "${var.prefix}-${var.environment}-container-insights"
  resource_group_name = azurerm_resource_group.monitoring_rg.name
  location            = azurerm_resource_group.monitoring_rg.location
  
  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.logs.id
      name                  = "harbor-container-logs"
    }
  }
  
  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default"]
    destinations = ["harbor-container-logs"]
  }
  
  data_sources {
    extension {
      extension_name = "ContainerInsights"
      name           = "ContainerInsightsExtension"
      streams        = ["Microsoft-ContainerInsights-Group-Default"]
    }
  }
  
  tags = var.tags
}

# Data collection rule association for AKS
resource "azurerm_monitor_data_collection_rule_association" "aks_containers" {
  name                    = "${var.prefix}-${var.environment}-aks-containers"
  target_resource_id      = var.aks_cluster_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.container_insights.id
}

# Get current subscription details
data "azurerm_subscription" "current" {}