output "service_account" {
  value       = "${module.anthos_platform_cluster.service_account}"
  description = "Service account used to create the cluster and node pool(s)"
}
