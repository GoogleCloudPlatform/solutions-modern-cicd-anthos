# Anthos Platform Demo Setup Instructions

Feedback and questions: cloud-sa-anthos-platform@google.com
Open an issue: [New issue in Buganizer](https://b.corp.google.com/issues/new?component=759009&template=1357580)

For more information please visit:
go/anthos-platform
go/anthos-platform-tech-pitch

For a user guide on what to do after the install, please go to:
go/anthos-platform-demo

## Contributing

To contribute follows these instrcutions for the development flow:

1. [Setup Local Repo](https://docs.google.com/document/d/1DMIAlcSmh6LaqkGLNxDunP6O_zpwPSchA0ywcSWdlXQ/edit#heading=h.w7ieayamciyz)

  ```shell
  git clone sso://cloudsolutionsarchitects/anthos-platform-setup
  cd anthos-platform-setup
  ```

1. [Configure the Gerrit Commit Hook Script](https://docs.google.com/document/d/1DMIAlcSmh6LaqkGLNxDunP6O_zpwPSchA0ywcSWdlXQ/edit#heading=h.csxq7bbwjeox)

  ```shell
  hookfile=`git rev-parse --git-dir`/hooks/commit-msg
  mkdir -p $(dirname $hookfile) 
  curl -Lo $hookfile \
    https://gerrit-review.googlesource.com/tools/hooks/commit-msg
  chmod +x $hookfile
  unset hookfile
  ```

1. Make your changes and commit them. Make sure your commit includes the auto-populated `Change-Id:` line in the message.

1. [Push the commit to Gerrit for review](https://docs.google.com/document/d/1DMIAlcSmh6LaqkGLNxDunP6O_zpwPSchA0ywcSWdlXQ/edit#heading=h.e4h88uajgibc)

  ```shell
  git push origin HEAD:refs/for/master
  ```

  A link to your review request will be printed.

## Quick Start

1. Install gcloud SDK and create a new project.

1. Run the following commands to setup Cloud Build
```

```shell
export PROJECT_ID=<INSERT_YOUR_PROJECT_ID>
export DOMAIN=<INSERT_YOUR_DOMAIN>
gcloud config set project ${PROJECT_ID}
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format 'value(projectNumber)')
gcloud services enable cloudbuild.googleapis.com
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com --role roles/owner
```

1. Run Cloud Build to create the necessary resources.

  ```shell
  gcloud builds submit --substitutions=_DOMAIN=${DOMAIN}
  ```

1. Jump to the [Configure GitLab section](#configure-gitlab)

## Pre-requisites

1. Install the following tools:

- [Terraform 0.12+](https://learn.hashicorp.com/terraform/getting-started/install.html)
- [Helm](https://helm.sh/docs/using_helm/#installing-helm)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

1. Clone this repo to your local machine.

1. Create a GCP project and activate it in your shell.

1. Provision a domain that you can use to host GitLab, you'll need to be able to create a wildcard DNS entry for that domain pointing to an A record.

## Install Anthos Platform

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

### Provision GitLab

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

### Configure GitLab

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
  git add ../namespaces/managed-apps/acm-tests
  git commit -m "Add acm-tests namespace"
  GIT_SSH_COMMAND="ssh -i ../../../ssh-keys/anthos-config-management"    git push --set-upstream origin master
  ```

1. You should now be able to go to the ACM repo and re-run tests. In the left nav of the ACM repo, click CI/CD->Pipelines.

1. Click the green "Run Pipeline" button.

1. On the next page click the green "Run Pipeline" button.

### Re-run CI

Some of the repositories created may have failed their first CI run due to missing runners. In this section you'll re-run CI on the repos that create images that other
pipelines use.

1. Go to the `platform-admins/kaniko-docker` repository in GitLab.

1. Click CI/CD in the left nav, then click the "Run Pipeline" button at the top.

1. Go to the `platform-admins/kustomize-docker` repository in GitLab.

1. Click CI/CD in the left nav, then click the "Run Pipeline" button at the top.

## TODOs

### Demo

- Instructions for locking down the ACM repo (theochamley@)
- Add Anthos Config Management Docker image to repo (theochamley@)
- Instructions on how to add a cluster (on-prem or GKE) (smchgee@)

### Sample repos

- Add more [kustomize bases](2_gitlab/repos/shared-kustomize-bases) (Java, Python, Ruby, etc), currently only have Go
- Add more [CI/CD patterns](2_gitlab/repos/shared-ci-cd) (Java, Ruby, Python, etc)

### Alternative tools

- Jenkins for CI/CD
- GitHub Enterprise for SCM
- Artifactory as the registry
- App Delivery for CD/rollout
