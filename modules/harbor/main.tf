# modules/harbor/main.tf

# Use Helm to deploy Harbor to AKS
resource "helm_release" "harbor" {
  name       = "harbor"
  repository = "https://helm.goharbor.io"
  chart      = "harbor"
  version    = var.harbor_chart_version
  namespace  = "harbor"
  create_namespace = true
  
  # Wait for deployment to complete
  wait = true
  
  # Set timeout for deployment
  timeout = 600
  
  # Set Harbor values
  values = [
    templatefile("${path.module}/templates/values.yaml", {
      domain              = var.harbor_domain
      tls_cert_secret     = var.tls_cert_secret
      admin_password      = var.admin_password
      database_host       = var.database_host
      database_password   = var.database_password
      redis_host          = var.redis_host
      redis_password      = var.redis_password
      storage_class_name  = var.storage_class_name
      registry_storage    = var.registry_storage
    })
  ]
  
  # Set additional values
  set {
    name  = "externalURL"
    value = "https://${var.harbor_domain}"
  }
  
  set {
    name  = "harborAdminPassword"
    value = var.admin_password
  }
  
  # Enable S2C2F Level 3 security features
  set {
    name  = "trivy.enabled"
    value = "true"
  }
  
  set {
    name  = "notary.enabled"
    value = "true"
  }
  
  # Configure Harbor to use Azure storage
  set {
    name  = "persistence.persistentVolumeClaim.registry.storageClass"
    value = var.storage_class_name
  }
  
  # Configure audit logs for S2C2F compliance
  set {
    name  = "log.level"
    value = "info"
  }
  
  # Depend on AKS being available
  depends_on = [var.aks_depends_on]
}

# Create Kubernetes ConfigMap for Harbor policies
resource "kubernetes_config_map" "harbor_policies" {
  metadata {
    name      = "harbor-policies"
    namespace = "harbor"
  }

  data = {
    "artifact_signing_policy.json" = file("${path.module}/policies/artifact_signing_policy.json")
    "image_scanning_policy.json"   = file("${path.module}/policies/image_scanning_policy.json")
  }
  
  depends_on = [helm_release.harbor]
}

# Create Kubernetes Secret for TLS certificate if not provided
resource "kubernetes_secret" "harbor_tls" {
  count = var.tls_cert_secret == "" ? 1 : 0
  
  metadata {
    name      = "harbor-tls"
    namespace = "harbor"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = var.tls_certificate
    "tls.key" = var.tls_key
  }
  
  depends_on = [helm_release.harbor]
}

# Apply Harbor policies using Kubernetes Job
resource "kubernetes_job" "apply_policies" {
  metadata {
    name      = "apply-harbor-policies"
    namespace = "harbor"
  }

  spec {
    template {
      metadata {
        labels = {
          app = "apply-harbor-policies"
        }
      }
      
      spec {
        container {
          name    = "apply-policies"
          image   = "bitnami/kubectl:latest"
          command = ["/bin/sh", "-c"]
          args    = [
            "curl -X POST -u \"admin:${var.admin_password}\" -H \"Content-Type: application/json\" -d @/policies/artifact_signing_policy.json https://${var.harbor_domain}/api/v2.0/projects/1/artifact_signing_policy && curl -X POST -u \"admin:${var.admin_password}\" -H \"Content-Type: application/json\" -d @/policies/image_scanning_policy.json https://${var.harbor_domain}/api/v2.0/projects/1/image_scanning_policy"
          ]
          
          volume_mount {
            name       = "policies"
            mount_path = "/policies"
          }
        }
        
        volume {
          name = "policies"
          config_map {
            name = kubernetes_config_map.harbor_policies.metadata[0].name
          }
        }
        
        restart_policy = "OnFailure"
      }
    }
    
    backoff_limit = 3
  }
  
  depends_on = [helm_release.harbor, kubernetes_config_map.harbor_policies]
}