provider "google" {
  version = "~> 2.17.0"
  project = "${var.project_id}"
}

resource "google_compute_network" "anthos-platform" {
  name                    = "anthos-platform"
  auto_create_subnetworks = false
  depends_on = [
    "google_project_service.compute"
  ]
}

resource "google_compute_subnetwork" "anthos-platform-central" {
  name          = "anthos-platform-central"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = "${google_compute_network.anthos-platform.self_link}"

  secondary_ip_range = [
    {
      range_name    = "anthos-platform-pods-prod"
      ip_cidr_range = "172.16.0.0/16"
    },
    {
      range_name    = "anthos-platform-pods-staging"
      ip_cidr_range = "172.17.0.0/16"
    },
    {
      range_name    = "anthos-platform-pods-dev"
      ip_cidr_range = "172.18.0.0/16"
    },
    {
      range_name    = "anthos-platform-services-prod"
      ip_cidr_range = "192.168.0.0/24"
    },
    {
      range_name    = "anthos-platform-services-staging"
      ip_cidr_range = "192.168.1.0/24"
    },
    {
      range_name    = "anthos-platform-services-dev"
      ip_cidr_range = "192.168.2.0/24"
    }
  ]
}

resource "google_compute_subnetwork" "anthos-platform-east" {
  name          = "anthos-platform-east"
  ip_cidr_range = "10.3.0.0/16"
  region        = "us-east1"
  network       = "${google_compute_network.anthos-platform.self_link}"
  secondary_ip_range = [
    {
      range_name    = "anthos-platform-pods-prod"
      ip_cidr_range = "172.19.0.0/16"
    },
    {
      range_name    = "anthos-platform-services-prod"
      ip_cidr_range = "192.168.3.0/24"
    }
  ]
}
