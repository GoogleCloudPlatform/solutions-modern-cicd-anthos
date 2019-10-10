module "gke-gitlab" {
  source            = "github.com/terraform-google-modules/terraform-google-gke-gitlab"
  project_id        = "${var.project_id}"
  domain            = "${var.domain}"
  certmanager_email = "no-reply@${var.project_id}.example.com"
  gitlab_runner_install = true
}

data "google_container_cluster" "ci" {
  name       = "ci"
  project    = "${var.project_id}"
  location   = "us-central1"
}

# provider "helm" {
#   service_account = "tiller"
#   install_tiller  = true
#   namespace       = "kube-system"

#   kubernetes {
#     host                   = "${data.google_container_cluster.ci.endpoint}"
#     client_certificate     = "${base64decode(data.google_container_cluster.ci.master_auth.0.client_certificate)}"
#     client_key             = "${base64decode(data.google_container_cluster.ci.master_auth.0.client_key)}"
#     cluster_ca_certificate = "${base64decode(data.google_container_cluster.ci.master_auth.0.cluster_ca_certificate)}"
#   }
# }

# resource "kubernetes_service_account" "tiller" {
#   metadata {
#     name      = "tiller"
#     namespace = "kube-system"
#   }
# }

# resource "kubernetes_cluster_role_binding" "tiller-admin" {
#   metadata {
#     name = "tiller-admin"
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = "tiller"
#     namespace = "kube-system"
#   }
# }


# data "helm_repository" "gitlab" {
#   name = "gitlab"
#   url  = "https://charts.gitlab.io"
# }

# resource "helm_release" "gitlab-runner" {
#   name       = "gitlab-runner"
#   repository = "${data.helm_repository.gitlab.name}"
#   chart      = "gitlab-runner"
#   version    = "0.7.0"
#   timeout    = 600

#   set {
#     name  = "gitlabUrl"
#     value = "true"
#   }

#   set {
#     name  = "runnerRegistrationToken"
#     value = "true"
#   }


#   depends_on = ["google_redis_instance.gitlab",
#     "google_sql_database.gitlabhq_production",
#     "google_sql_user.gitlab",
#     "kubernetes_cluster_role_binding.tiller-admin",
#     "kubernetes_storage_class.pd-ssd",
#   ]
# }