# Anthos Platform Demo Setup Instructions

For more information please visit:
go/anthos-platform
go/anthos-platform-tech-pitch

For a user guide on what to do after the install, please go to:
go/anthos-platform-demo

### Pre-requisites

1. Clone this repo to your local machine.

1. Install Docker, Terraform, Helm and kubectl

1. Create a GCP project and activate it in your shell.

1. Replace your project ID in each of the terraform.tfvars files:

  ```shell
  export PROJECT=$(gcloud config get-value project)
  sed -i "s/YOUR_PROJECT_ID/${PROJECT}/g" 0_foundation/terraform.tfvars
  sed -i "s/YOUR_PROJECT_ID/${PROJECT}/g" 1_clusters/terraform.tfvars
  sed -i "s/YOUR_PROJECT_ID/${PROJECT}/g" 2_gitlab/terraform.tfvars
  ```

### Provision infrastructure

1. Create foundational infrastructure (networks, subnetworks, etc)

  ```shell
  cd 0_foundation
  terraform init
  terraform plan # ensure no errors
  terraform apply # type yes to confirm
  cd ..
  ```

### Provision GKE clusters

1. Create the GKE clusters that will be used for prod, staging, CI, etc.

  ```shell
  cd 1_clusters
  terraform init
  terraform plan # ensure no errors
  terraform apply # type yes to confirm
  cd ..
  ```

### Provision and configure GitLab

1. Configure the domain you'll use for Gitlab in the terraform.tfvars file

  ```shell
  cd 2_gitlab
  export DOMAIN=example.org
  # Gitlab URL will be gitlab.$DOMAIN
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

    *.$DOMAIN -> IP_ADDRESS

1. Ensure that the DNS change has propagated by running a DNS query against gitlab.$DOMAIN, making sure that it returns your IP address from above.

1. Get credentails for the GitLab cluster and get the initial root password.

  ```shell
  gcloud container clusters get-credentials gitlab --region us-central1
  kubectl get secrets gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d
  ```

1. Log in to GitLab with the root user and password printed in the previous step.

1. Go to https://${GITLAB_HOSTNAME}/profile/personal_access_tokens, to create an access token for project creation that has access to all scopes:

![](2_gitlab/images/access-token.png)

1. Run the script to populate repos in GitLab. It will ask you for the token you just created.

  ```shell
  ./create-repos.sh
  cd ..
  ```

### Set up Anthos Config Management

1. Install Anthos Config Management in all of your clusters:

  ```shell
  cd 3_acm
  ./install_acm.sh
  cd ..
  ```

1. Go to the platform-admins/anthos-config-management repository.

1. In the left nav, go to Settings->CI/CD. Expand the runners section.

1. Copy the registration token in the Specific Runners section.

1. Add a new app namespace in the ACM repo to run ACM tests. You'll be prompted to input the runner registration token. The name of the app must be `acm-tests`.

  ```shell
  cd 2_gitlab/repos/anthos-config-management/templates
  export APP_NAME=acm-tests
  ./new-app.sh
  git add namespaces/managed-apps/acm-tests
  git commit -m "Add acm-tests namespace"
  GIT_SSH_COMMAND="ssh -i ../../../ssh-keys/anthos-config-management"    git push --set-upstream origin master
  ```

1. You should now be able to go to the ACM repo and re-run tests. In the left nav of the ACM repo, click CI/CD->Pipelines.

1. Click the green "Run Pipeline" button.

1. On the next page click the green "Run Pipeline" button.

## TODO

- Add Anthos Config Management Docker image to repo (theochamley@)
- Add instructions on how to add a cluster (on-prem or GKE)
