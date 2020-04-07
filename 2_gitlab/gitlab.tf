module "gke-gitlab" {
  source            = "github.com/terraform-google-modules/terraform-google-gke-gitlab?ref=master"
  project_id        = "${var.project_id}"
  domain            = "${var.domain}"
  certmanager_email = "no-reply@${var.project_id}.example.com"
  gitlab_address_name = "gitlab"
  gitlab_runner_install = true
  gitlab_db_name    = "gitlab-${lower(random_id.database_id.hex)}"
}

data "google_compute_address" "gitlab" {
  project       = "${var.project_id}"
  region        = "us-central1"
  name          = "gitlab"
}

resource "random_id" "database_id" {
  byte_length = 8
}