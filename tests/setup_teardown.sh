#!/bin/bash

# Fail on any error.
set -e

sa_creds=74668_ci-service-account
project_id=anthos-platform-ci-env
subdomain=ci
domain=${subdomain}.demo.anthos-platform.dev

# Set the project ID for CI
gcloud config set project ${project_id}

# Activate the service account
gcloud auth activate-service-account --key-file="${KOKORO_KEYSTORE_DIR}/${sa_creds}"

# Display commands, now that creds are set.
set -x

# Make sure the project is clean before running the setup
gcloud builds submit --config=cloudbuild-destroy.yaml

# Deploy the platform
gcloud builds submit --config=cloudbuild.yaml --substitutions=_DOMAIN=${domain}

# If the setup succeeded then tear it down.
if [ $? -eq 0 ]; then
	sleep 5m
	# Clean up after the run
	gcloud builds submit --config=cloudbuild-destroy.yaml
fi

echo "All passed"
