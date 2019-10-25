
output "gitlab_address" {
  value       = "${data.google_compute_address.gitlab.address}"
  description = "Point your wildcard domain to this IP address as an A record"
}

output "gitlab_domain" {
  value       = "${var.domain}"
  description = "Domain used to deploy Gitlab."
}