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

module "anthos-platform-dev" {
  source            = "./modules/anthos-platform-cluster"
  project_id        = "${var.project_id}"
  name              = "dev-us-central1"
  region            = "us-central1"
  network           = "${data.google_compute_network.anthos-platform.name}"
  subnetwork        = "${data.google_compute_subnetwork.anthos-platform-central.name}"
  ip_range_pods     = "anthos-platform-pods-dev"
  ip_range_services = "anthos-platform-services-dev"
}

module "anthos-platform-staging" {
  source            = "./modules/anthos-platform-cluster"
  project_id        = "${var.project_id}"
  name              = "staging-us-central1"
  region            = "us-central1"
  network           = "${data.google_compute_network.anthos-platform.name}"
  subnetwork        = "${data.google_compute_subnetwork.anthos-platform-central.name}"
  ip_range_pods     = "anthos-platform-pods-staging"
  ip_range_services = "anthos-platform-services-staging"
}

module "anthos-platform-prod-central" {
  source            = "./modules/anthos-platform-cluster"
  project_id        = "${var.project_id}"
  name              = "prod-us-central1"
  region            = "us-central1"
  network           = "${data.google_compute_network.anthos-platform.name}"
  subnetwork        = "${data.google_compute_subnetwork.anthos-platform-central.name}"
  ip_range_pods     = "anthos-platform-pods-prod"
  ip_range_services = "anthos-platform-services-prod"
}

module "anthos-platform-prod-east" {
  source            = "./modules/anthos-platform-cluster"
  project_id        = "${var.project_id}"
  name              = "prod-us-east1"
  region            = "us-east1"
  network           = "${data.google_compute_network.anthos-platform.name}"
  subnetwork        = "${data.google_compute_subnetwork.anthos-platform-east.name}"
  ip_range_pods     = "anthos-platform-pods-prod"
  ip_range_services = "anthos-platform-services-prod"
}
