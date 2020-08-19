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

resource "google_service_account" "service_account" {
  project      = var.project_id
  account_id   = "tf-sa-${var.name}"
  display_name = "Cluster Service Account for ${var.name}"
}

resource "google_project_iam_member" "cluster_iam_logginglogwriter" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_iam_monitoringmetricwriter" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_iam_monitoringviewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_iam_artifactregistryreader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

module "anthos_platform_cluster" {
  source             = "terraform-google-modules/kubernetes-engine/google//modules/beta-public-cluster"
  version            = "~> 10.0.0"
  project_id         = var.project_id
  name               = var.name
  region             = var.region
  network            = var.network
  subnetwork         = var.subnetwork
  ip_range_pods      = var.ip_range_pods
  ip_range_services  = var.ip_range_services
  kubernetes_version = var.gke_kubernetes_version
  release_channel    = var.release_channel
  regional           = true

  enable_binary_authorization = true

  create_service_account = false
  service_account        = google_service_account.service_account.email
  identity_namespace     = "${var.project_id}.svc.id.goog"
  node_metadata          = "GKE_METADATA_SERVER"

  remove_default_node_pool = true

  node_pools = [
    {
      name         = "wi-pool"
      machine_type = var.machine_type
      min_count    = var.minimum_node_pool_instances
      max_count    = var.maximum_node_pool_instances
      auto_upgrade = true
    },
  ]
}

