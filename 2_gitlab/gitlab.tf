module "gke-gitlab" {
  source            = "github.com/terraform-google-modules/terraform-google-gke-gitlab"
  project_id        = "${var.project_id}"
  domain            = "${var.domain}"
  certmanager_email = "no-reply@${var.project_id}.example.com"
  gitlab_address_name = "gitlab"
  gitlab_runner_install = true
}

data "google_compute_address" "gitlab" {
  project       = "${var.project_id}"
  region        = "us-central1"
  name          = "gitlab"
}
