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

provider "google" {
  version = "~> 3.44.0"
  project = var.project_id
}

resource "google_compute_network" "anthos-platform" {
  name                    = "anthos-platform"
  auto_create_subnetworks = false
  depends_on              = [module.project-services.project_id]
}

resource "google_compute_subnetwork" "anthos-platform-central1" {
  name          = "anthos-platform-central1"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.anthos-platform.self_link

  secondary_ip_range {
    range_name    = "anthos-platform-pods-prod"
    ip_cidr_range = "172.16.0.0/16"
  }
  secondary_ip_range {
    range_name    = "anthos-platform-services-prod"
    ip_cidr_range = "192.168.2.0/24"
  }
}

resource "google_compute_subnetwork" "anthos-platform-east1" {
  name          = "anthos-platform-east1"
  ip_cidr_range = "10.3.0.0/16"
  region        = "us-east1"
  network       = google_compute_network.anthos-platform.self_link
  secondary_ip_range {
    range_name    = "anthos-platform-pods-prod"
    ip_cidr_range = "172.17.0.0/16"
  }
  secondary_ip_range {
    range_name    = "anthos-platform-services-prod"
    ip_cidr_range = "192.168.3.0/24"
  }
}

resource "google_compute_subnetwork" "anthos-platform-west1" {
  name          = "anthos-platform-west1"
  ip_cidr_range = "10.4.0.0/16"
  region        = "us-west1"
  network       = google_compute_network.anthos-platform.self_link

  secondary_ip_range {
    range_name    = "anthos-platform-pods-dev"
    ip_cidr_range = "172.18.0.0/16"
  }
  secondary_ip_range {
    range_name    = "anthos-platform-services-dev"
    ip_cidr_range = "192.168.4.0/24"
  }
}

resource "google_compute_subnetwork" "anthos-platform-west2" {
  name          = "anthos-platform-west2"
  ip_cidr_range = "10.5.0.0/16"
  region        = "us-west2"
  network       = google_compute_network.anthos-platform.self_link

  secondary_ip_range {
    range_name    = "anthos-platform-pods-staging"
    ip_cidr_range = "172.19.0.0/16"
  }
  secondary_ip_range {
    range_name    = "anthos-platform-services-staging"
    ip_cidr_range = "192.168.5.0/24"
  }
}
