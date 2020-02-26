locals {
  cluster_type = "simple-regional"
}

provider "google" {
  project = "${var.project_id}"
}

data "google_compute_network" "anthos-platform" {
  name = "anthos-platform"
}

data "google_compute_subnetwork" "anthos-platform-central" {
  name = "anthos-platform-central"
  region = "us-central1"
}

data "google_compute_subnetwork" "anthos-platform-east" {
  name = "anthos-platform-east"
  region = "us-east1"
}

module "anthos-platform-prod-central" {
  source                 = "github.com/terraform-google-modules/terraform-google-kubernetes-engine?ref=v7.2.0"
  project_id             = "${var.project_id}"
  name                   = "prod-us-central1"
  regional               = true
  region                 = "us-central1"
  network                = "${data.google_compute_network.anthos-platform.name}"
  subnetwork             = "${data.google_compute_subnetwork.anthos-platform-central.name}"
  ip_range_pods          = "anthos-platform-pods-prod"
  ip_range_services      = "anthos-platform-services-prod"
  create_service_account = false
  service_account        = "${var.compute_engine_service_account}"
  kubernetes_version     = "${var.gke_kubernetes_version}"
}

module "anthos-platform-prod-east" {
  source                 = "github.com/terraform-google-modules/terraform-google-kubernetes-engine?ref=v7.2.0"
  project_id             = "${var.project_id}"
  name                   = "prod-us-east1"
  regional               = true
  region                 = "us-east1"
  network                = "${data.google_compute_network.anthos-platform.name}"
  subnetwork             = "${data.google_compute_subnetwork.anthos-platform-east.name}"
  ip_range_pods          = "anthos-platform-pods-prod"
  ip_range_services      = "anthos-platform-services-prod"
  create_service_account = false
  service_account        = "${var.compute_engine_service_account}"
  kubernetes_version     = "${var.gke_kubernetes_version}"
}

module "anthos-platform-staging" {
  source                 = "github.com/terraform-google-modules/terraform-google-kubernetes-engine?ref=v7.2.0"
  project_id             = "${var.project_id}"
  name                   = "staging-us-central1"
  regional               = true
  region                 = "us-central1"
  network                = "${data.google_compute_network.anthos-platform.name}"
  subnetwork             = "${data.google_compute_subnetwork.anthos-platform-central.name}"
  ip_range_pods          = "anthos-platform-pods-staging"
  ip_range_services      = "anthos-platform-services-staging"
  create_service_account = false
  service_account        = "${var.compute_engine_service_account}"
  kubernetes_version     = "${var.gke_kubernetes_version}"
}


module "anthos-platform-dev" {
  source                 = "github.com/terraform-google-modules/terraform-google-kubernetes-engine?ref=v7.2.0"
  project_id             = "${var.project_id}"
  name                   = "dev-us-central1"
  regional               = true
  region                 = "us-central1"
  network                = "${data.google_compute_network.anthos-platform.name}"
  subnetwork             = "${data.google_compute_subnetwork.anthos-platform-central.name}"
  ip_range_pods          = "anthos-platform-pods-dev"
  ip_range_services      = "anthos-platform-services-dev"
  create_service_account = false
  service_account        = "${var.compute_engine_service_account}"
  kubernetes_version     = "${var.gke_kubernetes_version}"
}
