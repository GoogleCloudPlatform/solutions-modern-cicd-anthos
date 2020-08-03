/**
 * Copyright 2019 Google LLC
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
  int_required_project_roles = [
    "roles/owner",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/containeranalysis.admin"
  ]
}

resource "google_project_iam_member" "int_test_project" {
  for_each = toset(local.int_required_project_roles)

  project = module.project.project_id
  role    = each.value
  member  = "serviceAccount:${var.int_sa_email}"
}
