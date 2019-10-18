locals {
  cluster_type = "simple-regional"
}

provider "google" {
  version = "~> 2.12.0"
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
  source                 = "github.com/terraform-google-modules/terraform-google-kubernetes-engine"
  project_id             = "${var.project_id}"
  name                   = "anthos-platform-prod-central"
  regional               = true
  region                 = "us-central1"
  network                = "${data.google_compute_network.anthos-platform.name}"
  subnetwork             = "${data.google_compute_subnetwork.anthos-platform-central.name}"
  ip_range_pods          = "anthos-platform-pods-prod"
  ip_range_services      = "anthos-platform-services-prod"
  create_service_account = false
  service_account        = "${var.compute_engine_service_account}"
}

module "anthos-platform-prod-east" {
  source                 = "github.com/terraform-google-modules/terraform-google-kubernetes-engine"
  project_id             = "${var.project_id}"
  name                   = "anthos-platform-prod-east"
  regional               = true
  region                 = "us-east1"
  network                = "${data.google_compute_network.anthos-platform.name}"
  subnetwork             = "${data.google_compute_subnetwork.anthos-platform-east.name}"
  ip_range_pods          = "anthos-platform-pods-prod"
  ip_range_services      = "anthos-platform-services-prod"
  create_service_account = false
  service_account        = "${var.compute_engine_service_account}"
}

module "anthos-platform-staging" {
  source                 = "github.com/terraform-google-modules/terraform-google-kubernetes-engine"
  project_id             = "${var.project_id}"
  name                   = "anthos-platform-staging"
  regional               = true
  region                 = "us-central1"
  network                = "${data.google_compute_network.anthos-platform.name}"
  subnetwork             = "${data.google_compute_subnetwork.anthos-platform-central.name}"
  ip_range_pods          = "anthos-platform-pods-staging"
  ip_range_services      = "anthos-platform-services-staging"
  create_service_account = false
  service_account        = "${var.compute_engine_service_account}"
}


module "anthos-platform-dev" {
  source                 = "github.com/terraform-google-modules/terraform-google-kubernetes-engine"
  project_id             = "${var.project_id}"
  name                   = "anthos-platform-dev"
  regional               = true
  region                 = "us-central1"
  network                = "${data.google_compute_network.anthos-platform.name}"
  subnetwork             = "${data.google_compute_subnetwork.anthos-platform-central.name}"
  ip_range_pods          = "anthos-platform-pods-dev"
  ip_range_services      = "anthos-platform-services-dev"
  create_service_account = false
  service_account        = "${var.compute_engine_service_account}"
}
