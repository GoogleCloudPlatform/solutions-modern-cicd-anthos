#!/bin/bash -xe
export TIMESTAMP=$(date +%s)

# Create project
export PROJECT_ID=anthos-platform-${TIMESTAMP}
gcloud projects create --folder=301779790514 ${PROJECT_ID}
gcloud beta billing projects link --billing-account=005196-7B06D5-7D3824 ${PROJECT_ID}
gcloud config set project ${PROJECT_ID}

# Configure Cloud BUild
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format 'value(projectNumber)')
gcloud services enable cloudbuild.googleapis.com
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com   --role roles/owner

# Allocate GitLab Address
gcloud services enable compute.googleapis.com
gcloud compute addresses create --region us-central1 gitlab

# Get a DNS Domain
curl -fsSL https://cloud-tutorial.dev/claim.sh | bash -s -- ap-${TIMESTAMP}
export SUBDOMAIN=ap-${TIMESTAMP}

# Configure DNS
export GITLAB_ADDRESS=$(gcloud compute addresses list --filter="name=('gitlab')" --format "value(address)")
gcloud dns record-sets transaction start --zone ${SUBDOMAIN}-zone
gcloud dns record-sets transaction add ${GITLAB_ADDRESS} --name "*.${SUBDOMAIN}.cloud-tutorial.dev" --type A --zone ${SUBDOMAIN}-zone --ttl 300
gcloud dns record-sets transaction execute --zone ${SUBDOMAIN}-zone

# Run Cloud Build
export DOMAIN=${SUBDOMAIN}.cloud-tutorial.dev
gcloud builds submit --substitutions=_DOMAIN=${DOMAIN}
