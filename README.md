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

1. Get the Gitlab Runner registration from the Admin Panel. (Overview->Runners)

1. Register a GitLab runner in the CI cluster.

  ```shell
  gcloud container clusters get-credentials anthos-platform-ci --region us-central1
  helm repo add gitlab https://charts.gitlab.io
  helm fetch gitlab/gitlab-runner --version 0.9.1
  # Need to fix certs to be able to use https URL
  helm template gitlab-runner-0.9.1.tgz -n ci --set gitlabUrl=http://${YOUR_GITLAB_HOSTNAME}/ --set runnerRegistrationToken=${TOKEN} --set rbac.create=true | kubectl apply -f -
  ```

1. Install Anthos Config Management in all of your clusters:

  ```shell
  cd 3_acm
  ./install_acm.sh
  cd ..
  ```

1. Configure a read only access token from your application repository that can be used for images to be pulled from GitLab. Go to Settings->Repository->Deploy Tokens, click "Expand".

Name it "anthos-platform-reader" and enable the "read_registry" scope.

Create a Kubernetes and add it to the ACM repo in your app namespace.

kubectl create secret docker-registry- -docker-server=https://registry.${DOMAIN} --docker-username=gitlab+deploy-token-1 --docker-password=<PASSWORD_FROM_UI> --dry-run gitlab-registry -o yaml > 2_gitlab/repos/anthos-config-management/namespaces/managed-apps/vic-test/gitlab-registry-secret.yaml

1. Commit that change back to the ACM repo.

  ```shell
  cd 2_gitlab/repos/anthos-config-management
  git commit -m "Add gitlab registry secret"
  git push origin master
  cd ..
  ```
