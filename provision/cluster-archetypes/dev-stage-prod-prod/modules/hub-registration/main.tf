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

locals {
  gke_hub_sa_key = google_service_account_key.gke_hub_key.private_key
}

resource "google_service_account_key" "gke_hub_key" {
  service_account_id = var.gke_hub_sa
}

module "gke_hub_registration" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 2.0"
  
  platform           = "linux"
  upgrade            = true
  module_depends_on  = [var.cluster_endpoint]

  create_cmd_entrypoint  = "${path.module}/gke_hub_registration.sh"
  create_cmd_body        = "${var.location} ${var.cluster_name} ${local.gke_hub_sa_key}"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "container hub memberships unregister ${var.cluster_name} --gke-cluster=${var.location}/${var.cluster_name} --project ${var.project_id}"
}