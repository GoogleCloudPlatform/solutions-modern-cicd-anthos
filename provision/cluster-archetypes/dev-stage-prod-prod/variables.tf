/**
 * Copyright 2018 Google LLC
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

variable "project_id" {
  description = "The project ID to host the cluster in"
}

variable keyring-region {
  type        = string
  default     = "us-central1"
  description = "Region used for key-ring"
}

variable "gke_hub_sa_name" {
  description = "Name for the GKE Hub SA stored as a secret `creds-gcp` in the `gke-connect` namespace."
  type        = string
  default     = "gke-hub-sa"
}