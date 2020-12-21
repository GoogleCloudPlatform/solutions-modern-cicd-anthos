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

resource "random_pet" "keyring-name" {
}

resource "null_resource" "resource-to-wait-on" {
  provisioner "local-exec" {
    command = "sleep 60" # one minute to allow eventual consistency of APIs avoiding failures downstream
  }
  depends_on = [module.project-services.project_id]
}

resource "google_kms_key_ring" "keyring" {
  name       = "attestor-key-ring-${random_pet.keyring-name.id}"
  location   = var.keyring-region
  depends_on = [null_resource.resource-to-wait-on]
}

# Create a Google Secret containing the keyring name
resource "google_secret_manager_secret" "keyring-secret" {
  provider = google-beta

  secret_id = "keyring-name"

  labels = {
    label = "keyring_for_binauthz_attestors"
  }

  replication {
    automatic = true
  }

}

resource "google_secret_manager_secret_version" "keyring-secret-version" {
  provider = google-beta

  secret = google_secret_manager_secret.keyring-secret.id

  secret_data = google_kms_key_ring.keyring.name
}

locals {
  attestors = [
    # Note: module for_each support coming soon
    "quality",
    "build",
    "security"
  ]
  admin_enabled_apis = [
    "binaryauthorization.googleapis.com",
    "cloudkms.googleapis.com",
    "containeranalysis.googleapis.com",
    "secretmanager.googleapis.com"
  ]

}

# APIs required for Binary Authorization
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 9.0"

  project_id = var.project_id

  disable_services_on_destroy = false

  activate_apis = local.admin_enabled_apis
}

# Create Quality Assurance attestor
module "quality-attestor" {
  source = "github.com/terraform-google-modules/terraform-google-kubernetes-engine/modules/binary-authorization"

  project_id = var.project_id

  attestor-name = local.attestors[0]
  keyring-id    = google_kms_key_ring.keyring.id

  disable_dependent_services  = false
  disable_services_on_destroy = false
}

# Create Builder attestor
module "build-attestor" {
  source = "github.com/terraform-google-modules/terraform-google-kubernetes-engine/modules/binary-authorization"

  project_id = var.project_id

  attestor-name = local.attestors[1]
  keyring-id    = google_kms_key_ring.keyring.id

  disable_dependent_services  = false
  disable_services_on_destroy = false
}

# Create Security attestor
module "security-attestor" {
  source = "github.com/terraform-google-modules/terraform-google-kubernetes-engine/modules/binary-authorization"
  #source = "terraform-google-modules/kubernetes-engine/google//modules/binary-authorization"
  #version = "~> 12.0.0"

  project_id = var.project_id

  attestor-name = local.attestors[2]
  keyring-id    = google_kms_key_ring.keyring.id

  disable_dependent_services  = false
  disable_services_on_destroy = false
}

resource "google_binary_authorization_policy" "policy" {
  admission_whitelist_patterns {
    # TODO: Figure out pattern for Gitlab's repo
    name_pattern = "quay.io/random-containers/*"
  }

  admission_whitelist_patterns {
    name_pattern = "gcr.io/${var.project_id}/*" # Pushes to GCR for project
  }

  global_policy_evaluation_mode = "ENABLE"

  # Production ready (all attestors required)
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "DRYRUN_AUDIT_LOG_ONLY"
    require_attestations_by = [
      module.quality-attestor.attestor,
      module.build-attestor.attestor,
      module.security-attestor.attestor
    ]
  }
  # Stage Environment Needs Build and Security
  cluster_admission_rules {
    cluster          = "${module.anthos-platform-staging.region}.${module.anthos-platform-staging.cluster-name}"
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "DRYRUN_AUDIT_LOG_ONLY"
    require_attestations_by = [
      module.build-attestor.attestor,
      module.security-attestor.attestor
    ]
  }
  # Development Environment, Build Quality Attestion only, non-authorative
  cluster_admission_rules {
    cluster          = "${module.anthos-platform-dev.region}.${module.anthos-platform-dev.cluster-name}"
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "DRYRUN_AUDIT_LOG_ONLY"
    require_attestations_by = [
      module.build-attestor.attestor
    ]
  }

}
