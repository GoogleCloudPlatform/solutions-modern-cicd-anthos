# Installation

1. Install Docker, Terraform, Helm and kubectl

1. Create a GCP project and activate it in your shell.

1. Replace your project ID in each of the terraform.tfvars files:

  ```shell
  export PROJECT=$(gcloud config get-value project)
  sed -i "s/YOUR_PROJECT_ID/${PROJECT}/g" 0_foundation/terraform.tfvars
  sed -i "s/YOUR_PROJECT_ID/${PROJECT}/g" 1_clusters/terraform.tfvars
  sed -i "s/YOUR_PROJECT_ID/${PROJECT}/g" 2_gitlab/terraform.tfvars
  ```

1. Create foundational infrastructure (networks, subnetworks, etc)

  ```shell
  cd 0_foundation
  terraform init
  terraform plan # ensure no errors
  terraform apply # type yes to confirm
  cd ..
  ```

1. Create the GKE clusters that will be used for prod, staging, CI, etc.

  ```shell
  cd 1_clusters
  terraform init
  terraform plan # ensure no errors
  terraform apply # type yes to confirm
  cd ..
  ```

1. Configure the domain you'll use for Gitlab in the terraform.tfvars file

  ```shell
  cd 2_gitlab
  export DOMAIN=example.org
  sed -i "s/YOUR_DOMAIN/${DOMAIN}/g" terraform.tfvars
  ```

1. Apply the terraform config to your project

  ```shell
  terraform init
  terraform plan # ensure no errors
  terraform apply # type yes to confirm
  cd ..
  ```

1. The GitLab domain and address will be printed after the commands complete. Setup DNS wildcard domain to point at the IP address.

1. Get credentails for the GitLab cluster and get the initial root password.

  ```shell
  gcloud container clusters get-credentials gitlab --region us-central1
  kubectl get secrets gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d
  ```

1. Log in to GitLab with the root user and password printed in the previous step.

1. Go to https://${GITLAB_HOSTNAME}/profile/personal_access_tokens, to create a sudo access token for project creation:

![](2_gitlab/images/access-token.png)

1. Run the script to populate repos in GitLab.

  ```shell
  ./create-repos.sh
  ```

1. Configure the repositories using the included script.

  ```shell
  ./configure-repos.sh
  cd ..
  ```

1. Install Anthos Config Management in all of your clusters:

  ```shell
  cd 3_acm
  ./install_acm.sh
  cd ..
  ```

## TODO
- Add Anthos Config Management Docker image to repo (theochamely@)
