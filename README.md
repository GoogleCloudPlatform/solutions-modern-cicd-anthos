# Modern CI/CD with Anthos

## Introduction

Kubernetes has given us wonderful abstraction that we can use to optimize the way we
develop, deploy, and maintain software projects across multiple environments.
In many cases though, Kubernetes is too complex for end users to learn and feel empowered with.
To alleviate this learning curve, many teams
are looking to build platform abstractions on top of Kubernetes to streamline onboarding and
reduce maintainenance for software projects.

In this repository we lay out a prescriptive way to create a multi-team software delivery platfrom
using Anthos. The platform has the following capabilities:

* Allow platform administrators to create and update best practices for provisioning apps
* Ensure App Developers can iterate independently in their own "landing zones" without interfereing with each other
* Allow security teams to seamlessly implement and propagate policy across the platform
* Use GitOps for deployment

For more details, please watch [this talk on Youtube](https://www.youtube.com/watch?v=MOALiliVoeg).

## Architecture Overview

After the [Quick Start](#quick-start) you will have the following infra:

![Anthos Platform Infrastructure](images/anthos-platform-infra.png)

* [GitLab deployed on GKE](https://cloud.google.com/solutions/deploying-production-ready-gitlab-on-gke) to host your source code repostitories
* 1 Dev cluster that can be used for iterative development with tools like [Skaffold](skaffold.dev)
* 1 Staging cluster
* 2 Production clusters in different GCP regions

Within GitLab you will have the following repo structure:
![Anthos Platform Repos](images/anthos-platform-repos.png)

[Starter repos](starter-repos/) have examples for:

* [CI stages/steps](starter-repos/shared-ci-cd/ci/)
* [CD methodologies](starter-repos/shared-ci-cd/cd/)
* [Kubernetes configs](starter-repos/shared-kustomize-bases/) (via Kustomize)
* An example [applcation repo](starter-repos/golang-template/) for a Go app

## Pre-requisites

1. Clone this repo to your local machine.

1. [Install gcloud SDK](https://cloud.google.com/sdk/install).

1. [Create a new GCP project.](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project)

## Quick Start

1. Run the following commands to setup Cloud Build

    ```shell
    export PROJECT_ID=<INSERT_YOUR_PROJECT_ID>
    gcloud config set project ${PROJECT_ID}
    export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format 'value(projectNumber)')
    gcloud services enable cloudbuild.googleapis.com
    gcloud services enable serviceusage.googleapis.com
    gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com   --role roles/owner
    ```

1. Provision the address that GitLab will use.

    ```shell
    gcloud services enable compute.googleapis.com
    gcloud compute addresses create --region us-central1 gitlab
    ```

1. Create a DNS sub-domain using cloud-tutorial.dev

    ```shell
    # Set this to a custom subdomain if youd like it to be more memorable
    export SUBDOMAIN=ap-$(date +%s)
    curl -o claim.sh https://cloud-tutorial.dev/claim.sh
    chmod +x claim.sh
    ./claim.sh ${SUBDOMAIN}
    rm claim.sh
    ```

1. Map your gitlab address above to your domain.

    ```shell
    export GITLAB_ADDRESS=$(gcloud compute addresses list --filter="name=('gitlab')" --format "value(address)")
    gcloud dns record-sets transaction start --zone ${SUBDOMAIN}-zone
    gcloud dns record-sets transaction add ${GITLAB_ADDRESS} --name "*.${SUBDOMAIN}.cloud-tutorial.dev" --type A --zone ${SUBDOMAIN}-zone --ttl 300
    gcloud dns record-sets transaction execute --zone ${SUBDOMAIN}-zone
    ```

1. Run Cloud Build to create the necessary resources. This takes around 30 minutes.

    ```shell
    export DOMAIN=${SUBDOMAIN}.cloud-tutorial.dev
    gcloud builds submit --substitutions=_DOMAIN=${DOMAIN}
    ```

1. Log in to your GitLab instance with the URL, username and password printed at the end of the build. Hang on to this password, you will need it for later steps.

1. Follow the steps in the [docs](docs/index.md) to go through a user journey (add, deploy, and change applications).

## Securing the ACM repository

At this stage, you should have a working ACM installation good enough for most
demos. If you want to follow production best practices, read
[Best practices for policy management with Anthos Config Management and GitLab](https://cloud.google.com/solutions/best-practices-for-policy-management-with-anthos-config-management).

Always leave at least one namespace defined in `namespaces/managed-apps`, otherwise ACM will
stop syncing.
