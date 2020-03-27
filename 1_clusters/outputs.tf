output "development__cluster-service-account" {
  value       = "${module.anthos-platform-dev.service_account}"
  description = "Service account used to create the cluster and node pool(s)"
}

output "staging__cluster-service-account" {
  value       = "${module.anthos-platform-staging.service_account}"
  description = "Service account used to create the cluster and node pool(s)"
}

output "prod-east__cluster-service-account" {
  value       = "${module.anthos-platform-prod-east.service_account}"
  description = "Service account used to create the cluster and node pool(s)"
}

output "prod-central__cluster-service-account" {
  value       = "${module.anthos-platform-prod-central.service_account}"
  description = "Service account used to create the cluster and node pool(s)"
}
