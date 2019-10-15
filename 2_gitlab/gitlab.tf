module "gke-gitlab" {
  source            = "github.com/terraform-google-modules/terraform-google-gke-gitlab"
  project_id        = "${var.project_id}"
  domain            = "${var.domain}"
  certmanager_email = "no-reply@${var.project_id}.example.com"
  gitlab_runner_install = true
}

