# modules/aks/main.tf

# Create Resource Group for AKS
resource "azurerm_resource_group" "aks_rg" {
  name     = "${var.prefix}-${var.environment}-aks-rg"
  location = var.location
  tags     = var.tags
}

# Create Log Analytics Workspace for AKS
resource "azurerm_log_analytics_workspace" "aks_logs" {
  name                = "${var.prefix}-${var.environment}-aks-logs"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# Create AKS cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-${var.environment}-aks"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "${var.prefix}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  # Configure node pools
  default_node_pool {
    name            = "system"
    node_count      = var.system_node_count
    vm_size         = var.system_node_vm_size
    vnet_subnet_id  = var.subnet_id
    os_disk_size_gb = var.os_disk_size_gb
    os_disk_type    = "Managed"
    type            = "VirtualMachineScaleSets"

    min_count = var.system_node_min_count
    max_count = var.system_node_max_count

    # OS configuration
    os_sku = "Ubuntu"

    # For S2C2F Level 3 compliance
    only_critical_addons_enabled = true


    # Node labels
    node_labels = {
      "role"        = "system"
      "environment" = var.environment
    }
  }

  # Identity configuration
  identity {
    type = "SystemAssigned"
  }

  # Network profile
  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    outbound_type      = "loadBalancer"
  }

  # Enable AAD integration
  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  # Enable Key Vault Secrets Provider
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Enable OMS agent for monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id
  }

  # Enable Microsoft Defender for Cloud
  microsoft_defender {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id
  }

  # Azure Policy for Kubernetes
  azure_policy_enabled = true

  # Configure maintenance window for S2C2F Level 3 compliance
  maintenance_window {
    allowed {
      day   = "Saturday"
      hours = [22, 23, 0, 1, 2, 3]
    }

    allowed {
      day   = "Sunday"
      hours = [22, 23, 0, 1, 2, 3]
    }
  }


  # Tags
  tags = var.tags
}

# Create User Node Pool for Harbor
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_node_vm_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.subnet_id
  os_disk_size_gb       = var.os_disk_size_gb
  os_type               = "Linux"
  os_sku                = "Ubuntu"
  
  min_count             = var.user_node_min_count
  max_count             = var.user_node_max_count

  # Node labels
  node_labels = {
    "role"        = "user"
    "environment" = var.environment
  }

  # For S2C2F Level 3 compliance in production
  node_taints = var.environment == "prod" ? ["security=s2c2f:NoSchedule"] : []

  # Tags
  tags = var.tags
}

# Create SecretProviderClass for Harbor
resource "kubernetes_manifest" "harbor_secret_provider" {
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "harbor-secrets"
      namespace = "harbor"
    }
    spec = {
      provider = "azure"
      parameters = {
        usePodIdentity : "false"
        useVMManagedIdentity : "true"
        userAssignedIdentityID : azurerm_kubernetes_cluster.aks.kubelet_identity[0].client_id
        keyvaultName : var.key_vault_name
        cloudName : ""
        objects : jsonencode([
          {
            objectName : "harbor-admin-password"
            objectType : "secret"
            objectVersion : ""
          },
          {
            objectName : "harbor-db-password"
            objectType : "secret"
            objectVersion : ""
          },
          {
            objectName : "harbor-redis-password"
            objectType : "secret"
            objectVersion : ""
          },
          {
            objectName : "harbor-tls-cert"
            objectType : "secret"
            objectVersion : ""
          }
        ])
        tenantId : data.azurerm_client_config.current.tenant_id
      }
      secretObjects : [
        {
          secretName : "harbor-secrets"
          type : "Opaque"
          data : [
            {
              objectName : "harbor-admin-password"
              key : "admin-password"
            },
            {
              objectName : "harbor-db-password"
              key : "db-password"
            },
            {
              objectName : "harbor-redis-password"
              key : "redis-password"
            }
          ]
        },
        {
          secretName : "harbor-tls-secret"
          type : "kubernetes.io/tls"
          data : [
            {
              objectName : "harbor-tls-cert"
              key : "tls.crt"
            },
            {
              objectName : "harbor-tls-cert"
              key : "tls.key"
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_kubernetes_cluster_node_pool.user
  ]
}

# Create Kubernetes namespace for Harbor
resource "kubernetes_namespace" "harbor" {
  metadata {
    name = "harbor"

    labels = {
      "app"         = "harbor"
      "environment" = var.environment
    }

    annotations = {
      "security.s2c2f.level" = "3"
    }
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_kubernetes_cluster_node_pool.user
  ]
}

# Create network policies for Harbor namespace
resource "kubernetes_network_policy" "harbor_default_deny" {
  metadata {
    name      = "default-deny"
    namespace = kubernetes_namespace.harbor.metadata[0].name
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress", "Egress"]
  }

  depends_on = [
    kubernetes_namespace.harbor
  ]
}

resource "kubernetes_network_policy" "harbor_allow_ingress" {
  metadata {
    name      = "allow-ingress"
    namespace = kubernetes_namespace.harbor.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "harbor"
      }
    }

    ingress {
      ports {
        port     = "80"
        protocol = "TCP"
      }

      ports {
        port     = "443"
        protocol = "TCP"
      }

      from {
        namespace_selector {}
      }
    }

    policy_types = ["Ingress"]
  }

  depends_on = [
    kubernetes_namespace.harbor
  ]
}

resource "kubernetes_network_policy" "harbor_allow_egress" {
  metadata {
    name      = "allow-egress"
    namespace = kubernetes_namespace.harbor.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        "app" = "harbor"
      }
    }

    egress {
      to {
        pod_selector {}
      }

      to {
        namespace_selector {}
      }

      to {
        ip_block {
          cidr = "0.0.0.0/0"
          except = [
            "169.254.0.0/16",
            "10.0.0.0/8",
            "172.16.0.0/12",
            "192.168.0.0/16"
          ]
        }
      }
    }

    policy_types = ["Egress"]
  }

  depends_on = [
    kubernetes_namespace.harbor
  ]
}

# Set up role bindings for S2C2F Level 3 compliance
resource "kubernetes_role" "harbor_admin" {
  metadata {
    name      = "harbor-admin"
    namespace = kubernetes_namespace.harbor.metadata[0].name
  }

  rule {
    api_groups = ["", "apps", "batch", "extensions"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["networkpolicies", "ingresses"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "harbor_admin_binding" {
  metadata {
    name      = "harbor-admin-binding"
    namespace = kubernetes_namespace.harbor.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.harbor_admin.metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = var.harbor_admin_group_id
    api_group = "rbac.authorization.k8s.io"
  }
}

# Configure AKS diagnostics
resource "azurerm_monitor_diagnostic_setting" "aks_diag" {
  name                       = "${var.prefix}-${var.environment}-aks-diag"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id
  
  enabled_log {
    category = "kube-apiserver"
    
  }
  
  enabled_log {
    category = "kube-audit"
    
  }
  
  enabled_log {
    category = "kube-audit-admin"
    
  }
  
  enabled_log {
    category = "kube-controller-manager"
    
  }
  
  enabled_log {
    category = "kube-scheduler"

  }
  
  enabled_log {
    category = "cluster-autoscaler"

  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
    
  }
}

# Get current client configuration
data "azurerm_client_config" "current" {}
