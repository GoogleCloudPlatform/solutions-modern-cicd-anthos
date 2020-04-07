#!/bin/bash

# Fail on any error.
set -e

sa_creds=74668_ci-service-account
project_id=anthos-platform-ci-env
domain=ap-anthos-platform-ci-env.cloud-tutorial.dev

# Activate the service account
gcloud auth activate-service-account --key-file="${KOKORO_KEYSTORE_DIR}/${sa_creds}"

# Display commands, now that creds are set.
set -x

gcloud config set project ${project_id}

gcloud builds submit --config=cloudbuild.yaml --substitutions=_DOMAIN=${domain}
sleep 5m
gcloud builds submit --config=cloudbuild-gcloud-destroy.yaml

echo "All passed"
