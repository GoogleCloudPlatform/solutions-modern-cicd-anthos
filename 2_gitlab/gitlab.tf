/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module "gke-gitlab" {
  source  = "terraform-google-modules/gke-gitlab/google"
  version = "~> 0.1.1"

  project_id            = var.project_id
  domain                = var.domain
  certmanager_email     = "no-reply@${var.project_id}.example.com"
  gitlab_address_name   = "gitlab"
  gitlab_runner_install = true
  gitlab_db_name        = "gitlab-${lower(random_id.database_id.hex)}"
}

data "google_compute_address" "gitlab" {
  project = var.project_id
  region  = "us-central1"
  name    = "gitlab"
}

resource "random_id" "database_id" {
  byte_length = 8
}
