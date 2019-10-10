provider "gitlab" {
    token = "${var.gitlab_token}"
    base_url = "https://${var.gitlab_hostname}/api/v4/"
    insecure = true
}

resource "gitlab_group" "platform-admins" {
  name        = "platform-admins"
  path        = "platform-admins"
  description = "An group of projects for Platform Admins"
  visibility_level = "internal"
}

resource "gitlab_project" "anthos-config-management" {
  name         = "anthos-config-management"
  description  = "Anthos Config Management repo"
  namespace_id = "${gitlab_group.platform-admins.id}"
  visibility_level = "internal"
}

resource "gitlab_project" "golang-template" {
  name         = "golang-template"
  description  = "Template for new Go applications"
  namespace_id = "${gitlab_group.platform-admins.id}"
  visibility_level = "internal"
}

resource "gitlab_project" "golang-template-env" {
  name         = "golang-template-env"
  description  = "Template for new Go app environment repos"
  namespace_id = "${gitlab_group.platform-admins.id}"
  visibility_level = "internal"
}

resource "gitlab_project" "shared-kustomize-bases" {
  name         = "shared-kustomize-bases"
  description  = "Kubernetes Application Configuration Bases"
  namespace_id = "${gitlab_group.platform-admins.id}"
  visibility_level = "internal"
}

resource "gitlab_project" "kaniko-docker" {
  name         = "kaniko-docker"
  description  = "Docker+Kaniko Docker image"
  namespace_id = "${gitlab_group.platform-admins.id}"
  visibility_level = "internal"
}

resource "gitlab_project" "kustomize-docker" {
  name         = "kustomize-docker"
  description  = "Kustomize Docker image"
  namespace_id = "${gitlab_group.platform-admins.id}"
  visibility_level = "internal"
}

resource "gitlab_project" "shared-ci-cd" {
  name         = "shared-ci-cd"
  description  = "Shared CI/CD configurations"
  namespace_id = "${gitlab_group.platform-admins.id}"
  visibility_level = "internal"
}


resource "gitlab_deploy_key" "acm-staging" {
  project = "platform-admins/anthos-config-management"
  title   = "Staging deploy key"
  key     = "${file("../../3_acm/ssh-keys/staging-ssh.pub")}"
  depends_on = ["gitlab_project.anthos-config-management"]
}

resource "gitlab_deploy_key" "acm-prod-central" {
  project = "platform-admins/anthos-config-management"
  title   = "Production Central deploy key"
  key     = "${file("../../3_acm/ssh-keys/prod-central-ssh.pub")}"
  depends_on = ["gitlab_project.anthos-config-management"]
}
resource "gitlab_deploy_key" "acm-prod-east" {
  project = "platform-admins/anthos-config-management"
  title   = "Production East deploy key"
  key     = "${file("../../3_acm/ssh-keys/prod-east-ssh.pub")}"
  depends_on = ["gitlab_project.anthos-config-management"]
}

resource "gitlab_deploy_key" "local-user-kaniko-docker-push" {
  project = "platform-admins/kaniko-docker"
  title   = "Local User deploy key"
  key     = "${file("../ssh-keys/kaniko-docker.pub")}"
  can_push = true
  depends_on = ["gitlab_project.kaniko-docker"]
}

resource "gitlab_deploy_key" "local-user-kustomize-docker-push" {
  project = "platform-admins/kustomize-docker"
  title   = "Local User deploy key"
  key     = "${file("../ssh-keys/kustomize-docker.pub")}"
  can_push = true
  depends_on = ["gitlab_project.kustomize-docker"]
}

resource "gitlab_deploy_key" "local-user-acm-push" {
  project = "platform-admins/anthos-config-management"
  title   = "Local User deploy key"
  key     = "${file("../ssh-keys/anthos-config-management.pub")}"
  can_push = true
  depends_on = ["gitlab_project.anthos-config-management"]
}

resource "gitlab_deploy_key" "local-user-kustomize-push" {
  project = "platform-admins/shared-kustomize-bases"
  title   = "Local User deploy key"
  key     = "${file("../ssh-keys/shared-kustomize-bases.pub")}"
  depends_on = ["gitlab_project.shared-kustomize-bases"]
  can_push = true
}

resource "gitlab_deploy_key" "local-user-ci-cd-push" {
  project = "platform-admins/shared-ci-cd"
  title   = "Local User deploy key"
  key     = "${file("../ssh-keys/shared-ci-cd.pub")}"
  depends_on = ["gitlab_project.shared-ci-cd"]
  can_push = true
}

resource "gitlab_deploy_key" "local-user-golang-template-push" {
  project = "platform-admins/golang-template"
  title   = "Local User deploy key"
  key     = "${file("../ssh-keys/golang-template.pub")}"
  depends_on = ["gitlab_project.golang-template"]
  can_push = true
}

resource "gitlab_deploy_key" "local-user-golang-template-env-push" {
  project = "platform-admins/golang-template-env"
  title   = "Local User deploy key"
  key     = "${file("../ssh-keys/golang-template-env.pub")}"
  depends_on = ["gitlab_project.golang-template-env"]
  can_push = true
}
