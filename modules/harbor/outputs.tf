# modules/harbor/outputs.tf

output "harbor_url" {
  description = "URL for Harbor registry"
  value       = "https://${var.harbor_domain}"
}

output "harbor_admin_username" {
  description = "Admin username for Harbor"
  value       = "admin"
}

output "harbor_namespace" {
  description = "Kubernetes namespace where Harbor is deployed"
  value       = helm_release.harbor.namespace
}

output "harbor_release_name" {
  description = "Helm release name for Harbor"
  value       = helm_release.harbor.name
}