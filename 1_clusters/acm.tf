
data "google_client_config" "default" {
}

provider "kubernetes" {
  name                   = "${module.anthos-platform-prod-central.name}"
  load_config_file       = false
  host                   = "https://${module.anthos-platform-prod-central.endpoint}"
  token                  = "${data.google_client_config.default.access_token}"
  cluster_ca_certificate = "${base64decode(module.anthos-platform-prod-central.ca_certificate)}"
}
