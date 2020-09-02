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

provider "gitlab" {
  token    = var.gitlab_token
  base_url = "https://${data.terraform_remote_state.gitlab.outputs.gitlab_hostname}/api/v4/"
  insecure = true
}

locals {
  ssh-key-path = var.ssh-key-path-base
}

resource "gitlab_group" "platform-admins" {
  name             = "platform-admins"
  path             = "platform-admins"
  description      = "An group of projects for Platform Admins"
  visibility_level = "internal"
}

resource "gitlab_project" "anthos-config-management" {
  name             = "anthos-config-management"
  description      = "Anthos Config Management repo"
  namespace_id     = gitlab_group.platform-admins.id
  visibility_level = "internal"
  default_branch   = "master"
}

resource "gitlab_project" "shared-kustomize-bases" {
  name             = "shared-kustomize-bases"
  description      = "Kubernetes Application Configuration Bases"
  namespace_id     = gitlab_group.platform-admins.id
  visibility_level = "internal"
  default_branch   = "master"
}

resource "gitlab_project" "kaniko-docker" {
  name             = "kaniko-docker"
  description      = "Docker+Kaniko Docker image"
  namespace_id     = gitlab_group.platform-admins.id
  visibility_level = "internal"
  default_branch   = "master"
}

resource "gitlab_project" "kustomize-docker" {
  name             = "kustomize-docker"
  description      = "Kustomize Docker image"
  namespace_id     = gitlab_group.platform-admins.id
  visibility_level = "internal"
  default_branch   = "master"
}

resource "gitlab_project" "shared-ci-cd" {
  name             = "shared-ci-cd"
  description      = "Shared CI/CD configurations"
  namespace_id     = gitlab_group.platform-admins.id
  visibility_level = "internal"
  default_branch   = "master"
}

resource "gitlab_project" "golang-template" {
  name             = "golang-template"
  description      = "Template for new Go applications"
  namespace_id     = gitlab_group.platform-admins.id
  visibility_level = "internal"
  default_branch   = "master"
}

resource "gitlab_project" "golang-template-env" {
  name             = "golang-template-env"
  description      = "Template for new Go app environment repos"
  namespace_id     = gitlab_group.platform-admins.id
  visibility_level = "internal"
  default_branch   = "master"
}

resource "gitlab_project" "java-template" {
  name             = "java-template"
  description      = "Template for new Java applications"
  namespace_id     = gitlab_group.platform-admins.id
  visibility_level = "internal"
  default_branch   = "master"
}

resource "gitlab_project" "java-template-env" {
  name             = "java-template-env"
  description      = "Template for new Java app environment repos"
  namespace_id     = gitlab_group.platform-admins.id
  visibility_level = "internal"
  default_branch   = "master"
}

resource "gitlab_deploy_key" "acm-staging-us-west2" {
  project    = "platform-admins/anthos-config-management"
  title      = "Staging deploy key"
  key        = file("${local.ssh-key-path}/staging-us-west2.pub")
  depends_on = [gitlab_project.anthos-config-management]
}

resource "gitlab_deploy_key" "acm-prod-us-central1" {
  project    = "platform-admins/anthos-config-management"
  title      = "Production us-central1 deploy key"
  key        = file("${local.ssh-key-path}/prod-us-central1.pub")
  depends_on = [gitlab_project.anthos-config-management]
}

resource "gitlab_deploy_key" "acm-prod-us-east1" {
  project    = "platform-admins/anthos-config-management"
  title      = "Production East deploy key"
  key        = file("${local.ssh-key-path}/prod-us-east1.pub")
  depends_on = [gitlab_project.anthos-config-management]
}

resource "gitlab_deploy_key" "local-user-kaniko-docker-push" {
  project    = "platform-admins/kaniko-docker"
  title      = "Local User deploy key"
  key        = file("${local.ssh-key-path}/kaniko-docker.pub")
  can_push   = true
  depends_on = [gitlab_project.kaniko-docker]
}

resource "gitlab_deploy_key" "local-user-kustomize-docker-push" {
  project    = "platform-admins/kustomize-docker"
  title      = "Local User deploy key"
  key        = file("${local.ssh-key-path}/kustomize-docker.pub")
  can_push   = true
  depends_on = [gitlab_project.kustomize-docker]
}

resource "gitlab_deploy_key" "local-user-acm-push" {
  project    = "platform-admins/anthos-config-management"
  title      = "Local User deploy key"
  key        = file("${local.ssh-key-path}/anthos-config-management.pub")
  can_push   = true
  depends_on = [gitlab_project.anthos-config-management]
}

resource "gitlab_deploy_key" "local-user-kustomize-push" {
  project    = "platform-admins/shared-kustomize-bases"
  title      = "Local User deploy key"
  key        = file("${local.ssh-key-path}/shared-kustomize-bases.pub")
  depends_on = [gitlab_project.shared-kustomize-bases]
  can_push   = true
}

resource "gitlab_deploy_key" "local-user-ci-cd-push" {
  project    = "platform-admins/shared-ci-cd"
  title      = "Local User deploy key"
  key        = file("${local.ssh-key-path}/shared-ci-cd.pub")
  depends_on = [gitlab_project.shared-ci-cd]
  can_push   = true
}

resource "gitlab_deploy_key" "local-user-golang-template-push" {
  project    = "platform-admins/golang-template"
  title      = "Local User deploy key"
  key        = file("${local.ssh-key-path}/golang-template.pub")
  depends_on = [gitlab_project.golang-template]
  can_push   = true
}

resource "gitlab_deploy_key" "local-user-golang-template-env-push" {
  project    = "platform-admins/golang-template-env"
  title      = "Local User deploy key"
  key        = file("${local.ssh-key-path}/golang-template-env.pub")
  depends_on = [gitlab_project.golang-template-env]
  can_push   = true
}

resource "gitlab_deploy_key" "local-user-java-template-push" {
  project    = "platform-admins/java-template"
  title      = "Local User deploy key"
  key        = file("${local.ssh-key-path}/java-template.pub")
  depends_on = [gitlab_project.java-template]
  can_push   = true
}

resource "gitlab_deploy_key" "local-user-java-template-env-push" {
  project    = "platform-admins/java-template-env"
  title      = "Local User deploy key"
  key        = file("${local.ssh-key-path}/java-template-env.pub")
  depends_on = [gitlab_project.java-template-env]
  can_push   = true
}
