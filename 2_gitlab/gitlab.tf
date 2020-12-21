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

module "gke-gitlab" {
  source  = "github.com/terraform-google-modules/terraform-google-gke-gitlab?ref=master"

  project_id            = var.project_id
  domain                = trimprefix(module.cloud-endpoints-dns-gitlab.endpoint_computed, "gitlab.")
  certmanager_email     = "no-reply@${var.project_id}.example.com"
  gitlab_runner_install = true
  gitlab_db_name        = "gitlab-${lower(random_id.database_id.hex)}"
  helm_chart_version    = "4.0.7"
  gke_version           = "1.15"
}

module "cloud-endpoints-dns-gitlab" {
  source  = "terraform-google-modules/endpoints-dns/google"
  version = "~> 2.0.1"

  project     = var.project_id
  name        = "gitlab"
  external_ip = module.gke-gitlab.gitlab_address
}

module "cloud-endpoints-dns-registry" {
  source  = "terraform-google-modules/endpoints-dns/google"
  version = "~> 2.0.1"

  project     = var.project_id
  name        = "registry"
  external_ip = module.gke-gitlab.gitlab_address

  depends_on = [module.cloud-endpoints-dns-gitlab]
}

resource "random_id" "database_id" {
  byte_length = 8
}

provider "kubernetes" {
  load_config_file = false

  cluster_ca_certificate = module.gke-gitlab.cluster_ca_certificate
  host                   = module.gke-gitlab.host
  token                  = module.gke-gitlab.token
}

resource "kubernetes_role" "kaniko-builder" {
  metadata {
    name = "kaniko-builder"
  }

  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    verbs          = ["*"]
  }
  rule {
    api_groups     = [""]
    resources      = ["pods"]
    verbs          = ["*"]
  }
  rule {
    api_groups     = [""]
    resources      = ["pods/exec"]
    verbs          = ["*"]
  }

  depends_on = [module.gke-gitlab]
}

# Required for allowing Skaffold to create/delete kaniko pods and secrets during image build
resource "kubernetes_role_binding" "ci-kaniko-builder" {
  metadata {
    name      = "ci-kaniko-builder"
    namespace = "default"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "kaniko-builder"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }

  depends_on = [module.gke-gitlab, kubernetes_role.kaniko-builder]
}
