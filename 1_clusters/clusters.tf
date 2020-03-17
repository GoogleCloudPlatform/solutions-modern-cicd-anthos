locals {
  cluster_type = "regional"
}

provider "google" {
  project = "${var.project_id}"
  version = "~> 3.13"
}

provider "google-beta" {
  project = "${var.project_id}"
  version = "~> 3.13"
}

data "google_compute_network" "anthos-platform" {
  name = "anthos-platform"
}

data "google_compute_subnetwork" "anthos-platform-central" {
  name   = "anthos-platform-central"
  region = "us-central1"
}

data "google_compute_subnetwork" "anthos-platform-east" {
  name   = "anthos-platform-east"
  region = "us-east1"
}

module "anthos-platform-prod-central" {
  source             = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/beta-public-cluster?ref=v7.3.0"
  project_id         = "${var.project_id}"
  name               = "prod-us-central1"
  regional           = true
  region             = "us-central1"
  network            = "${data.google_compute_network.anthos-platform.name}"
  subnetwork         = "${data.google_compute_subnetwork.anthos-platform-central.name}"
  ip_range_pods      = "anthos-platform-pods-prod"
  ip_range_services  = "anthos-platform-services-prod"
  kubernetes_version = "${var.gke_kubernetes_version}"

  identity_namespace       = "${var.project_id}.svc.id.goog"
  service_account          = "create"
  node_metadata            = "GKE_METADATA_SERVER"
  remove_default_node_pool = true

  node_pools = [
    {
      name         = "wi-pool"
      min_count    = "${var.minimum_node_pool_instances}"
      max_count    = "${var.maximum_node_pool_instances}"
      auto_upgrade = true
    }
  ]
}

module "anthos-platform-prod-east" {
  source             = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/beta-public-cluster?ref=v7.3.0"
  project_id         = "${var.project_id}"
  name               = "prod-us-east1"
  regional           = true
  region             = "us-east1"
  network            = "${data.google_compute_network.anthos-platform.name}"
  subnetwork         = "${data.google_compute_subnetwork.anthos-platform-east.name}"
  ip_range_pods      = "anthos-platform-pods-prod"
  ip_range_services  = "anthos-platform-services-prod"
  kubernetes_version = "${var.gke_kubernetes_version}"

  identity_namespace       = "${var.project_id}.svc.id.goog"
  service_account          = "create"
  node_metadata            = "GKE_METADATA_SERVER"
  remove_default_node_pool = true

  node_pools = [
    {
      name         = "wi-pool"
      min_count    = "${var.minimum_node_pool_instances}"
      max_count    = "${var.maximum_node_pool_instances}"
      auto_upgrade = true
    }
  ]
}

module "anthos-platform-staging" {
  source             = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/beta-public-cluster?ref=v7.3.0"
  project_id         = "${var.project_id}"
  name               = "staging-us-central1"
  regional           = true
  region             = "us-central1"
  network            = "${data.google_compute_network.anthos-platform.name}"
  subnetwork         = "${data.google_compute_subnetwork.anthos-platform-central.name}"
  ip_range_pods      = "anthos-platform-pods-staging"
  ip_range_services  = "anthos-platform-services-staging"
  kubernetes_version = "${var.gke_kubernetes_version}"

  identity_namespace       = "${var.project_id}.svc.id.goog"
  service_account          = "create"
  node_metadata            = "GKE_METADATA_SERVER"
  remove_default_node_pool = true

  node_pools = [
    {
      name         = "wi-pool"
      min_count    = "${var.minimum_node_pool_instances}"
      max_count    = "${var.maximum_node_pool_instances}"
      auto_upgrade = true
    }
  ]
}

module "anthos-platform-dev" {
  source             = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/beta-public-cluster?ref=v7.3.0"
  project_id         = "${var.project_id}"
  name               = "dev-us-central1"
  regional           = true
  region             = "us-central1"
  network            = "${data.google_compute_network.anthos-platform.name}"
  subnetwork         = "${data.google_compute_subnetwork.anthos-platform-central.name}"
  ip_range_pods      = "anthos-platform-pods-dev"
  ip_range_services  = "anthos-platform-services-dev"
  kubernetes_version = "${var.gke_kubernetes_version}"

  identity_namespace       = "${var.project_id}.svc.id.goog"
  service_account          = "create"
  node_metadata            = "GKE_METADATA_SERVER"
  remove_default_node_pool = true

  node_pools = [
    {
      name         = "wi-pool"
      min_count    = "${var.minimum_node_pool_instances}"
      max_count    = "${var.maximum_node_pool_instances}"
      auto_upgrade = true
    }
  ]
}