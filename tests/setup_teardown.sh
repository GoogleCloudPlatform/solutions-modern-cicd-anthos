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
subdomain=ci
domain=${subdomain}.demo.anthos-platform.dev

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

# Make sure the project is clean before running the setup
gcloud builds submit --config=cloudbuild-destroy.yaml --substitutions=_DOMAIN=${domain}

# Deploy the platform
gcloud builds submit --config=cloudbuild.yaml --substitutions=_DOMAIN=${domain}

# If the setup succeeded then tear it down.
if [ $? -eq 0 ]; then
	sleep 5m
	# Clean up after the run
	gcloud builds submit --config=cloudbuild-destroy.yaml --substitutions=_DOMAIN=${domain}
fi

echo "All passed"
