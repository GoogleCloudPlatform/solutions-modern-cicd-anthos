#!/bin/bash
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Fail on any error.
set -e

sa_creds=74668_ci-service-account
project_id=anthos-platform-ci-env

# Set the project ID for CI
gcloud config set project ${project_id}

if [ -n ${GITHUB_ACTIONS} ]; then
  # Running in GitHub Actions
  KEY_FILE=/tmp/service-account.json
  echo "${GCP_SERVICE_ACCOUNT_JSON}" > ${KEY_FILE}
else
  # Running in Kokoro
  KEY_FILE="${KOKORO_KEYSTORE_DIR}/${sa_creds}"
fi

# Activate the service account
gcloud auth activate-service-account --key-file=${KEY_FILE}

# Display commands, now that creds are set.
set -x

# Retrieve current email
INT_SA_EMAIL=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")

# Create a temporary project for tests
gcloud builds submit --config=test/setup/cloudbuild.yaml \
  --substitutions _ORG_ID=${_ORG_ID},_FOLDER_ID=${_FOLDER_ID},_BILLING_ACCOUNT=${_BILLING_ACCOUNT},_INT_SA_EMAIL=${INT_SA_EMAIL}

# Wait for the project to be fully created
sleep 60

# Retrieve the newly created project
TEMP_PROJECT_ID=$(gcloud projects list --filter="labels.cft-ci-module=anthos-platform" --format=json --sort-by=~createTime | jq -r "first(.[]).projectId")

echo "Running tests inside project: $TEMP_PROJECT_ID"

# Deploy the platform
gcloud builds submit --config=cloudbuild.yaml --substitutions _PROJECT_ID=${TEMP_PROJECT_ID}

# If the setup succeeded then tear it down.
if [ $? -eq 0 ]; then
	sleep 5m
	# Clean up after the run
	gcloud builds submit --config=cloudbuild-destroy.yaml --substitutions _PROJECT_ID=${TEMP_PROJECT_ID}
fi

echo "All passed"
