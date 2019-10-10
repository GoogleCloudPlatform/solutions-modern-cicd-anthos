
output "gitlab_address" {
  value       = "${module.gke-gitlab.gitlab_address}"
  description = "Point your wildcard domain to this IP address as an A record"
}

output "gitlab_domain" {
  value       = "${var.domain}"
  description = "Domain used to deploy Gitlab."
}