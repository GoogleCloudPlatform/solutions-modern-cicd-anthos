# Modern CI/CD with Anthos

Table of contents

1. Clone this repo to your local machine.

1. [Install gcloud SDK](https://cloud.google.com/sdk/install).

1. [Create a new GCP project.](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project)

    <!-- TODO Find URL-->
1. Enable billing for GCP project

    <!-- TODO Link for regions -->
1. Set a region to deploy infrastructure

    ```shell
    export REGION="<INSERT_YOUR_REGION>"
    gcloud config set compute/region ${REGION}
    ```

### Build Infrastructure

1. Run the following commands to setup Cloud Build

    ```shell
    export PROJECT_ID=<INSERT_YOUR_PROJECT_ID>
    gcloud config set core/project ${PROJECT_ID}
    export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format 'value(projectNumber)')
    gcloud services enable cloudbuild.googleapis.com
    gcloud services enable serviceusage.googleapis.com
    gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com   --role roles/owner
    ```

1. Provision the address that GitLab will use.

    ```shell
    gcloud services enable compute.googleapis.com
    gcloud compute addresses create --region ${REGION} gitlab
    ```

1. Create a DNS sub-domain using anthos-platform.dev

    ```shell
    # Set this to a custom subdomain if youd like it to be more memorable
    export SUBDOMAIN=ap-$(date +%s)
    curl -sL -o claim.sh https://claim.anthos-platform.dev/claim.sh
    chmod +x claim.sh
    ./claim.sh ${SUBDOMAIN}
    rm claim.sh
    ```

1. Map your gitlab address above to your domain.

    ```shell
    export GITLAB_ADDRESS=$(gcloud compute addresses list --filter="name=('gitlab')" --format "value(address)")
    gcloud dns record-sets transaction start --zone ${SUBDOMAIN}-zone
    gcloud dns record-sets transaction add ${GITLAB_ADDRESS} \
        --name "*.${SUBDOMAIN}.demo.anthos-platform.dev" \
        --type A \
        --zone ${SUBDOMAIN}-zone \
        --ttl 300
    gcloud dns record-sets transaction execute --zone ${SUBDOMAIN}-zone
    ```

1. Run Cloud Build to create the necessary resources.

    ```shell
    export DOMAIN=${SUBDOMAIN}.demo.anthos-platform.dev
    gcloud builds submit --substitutions=_DOMAIN=${DOMAIN}
    ```

    > :warning: This operation may take up to 30 minutes depending on region. Do not close the console or connection as the operation is NOT idempotent. If a failure occurs, [clean up](#clean-up) the environment and attempt again.

1. Log in to your GitLab instance with the URL, username and password printed at the end of the build. Hang on to this password, you will need it for later steps.

1. Follow the steps in the [docs](docs/index.md) to go through a user journey (add, deploy, and change applications).

### Important Variables

1. Take note and record the Password for your Gitlab account.
1. URL for Gitlab

    ```shell
    echo "https://gitlab.${DOMAIN}"
    ```

### Clean Up
<!-- TODO: Domain name deletion will be added later  -->
1. Remove infrastructure

    ```shell
    gcloud builds submit --config cloudbuild-destroy.yaml
    ```

1. Unset variables (optional)

    ```shell
    unset PROJECT_ID
    unset DOMAIN
    unset SUBDOMAIN
    unset REGION
    ```

## Securing the ACM repository

At this stage, you should have a working ACM installation good enough for most
demos. If you want to follow production best practices, read
[Best practices for policy management with Anthos Config Management and GitLab](https://cloud.google.com/solutions/best-practices-for-policy-management-with-anthos-config-management).

Always leave at least one namespace defined in `namespaces/managed-apps`, otherwise ACM will
stop syncing.
