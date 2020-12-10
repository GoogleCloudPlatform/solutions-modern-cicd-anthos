#!/bin/bash -x
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

if [ -z ${PROJECT_ID} ]; then
  echo "The GCP Project ID that will contain the GSAs and their IAM Role Bindings."
  read -s -p "What is the GCP Project ID that will contain the GSAs and their IAM Role Bindings?" PROJECT_ID
fi

# TODO: Check APPS environment variable, otherwise set APPS to default list
APPS="online-boutique-loadgen online-boutique online-boutique-frontend petabank"

# Give each Online Boutique/Petabank app GSA the appropriate IAM roles
for appname in ${APPS}; do
    GSA="${appname}-gsa@${PROJECT_ID}.iam.gserviceaccount.com"
    gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${GSA} --role 'roles/monitoring.metricWriter'
    gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${GSA} --role 'roles/monitoring.viewer'
    gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${GSA} --role 'roles/stackdriver.resourceMetadata.writer'
    gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${GSA} --role 'roles/cloudtrace.agent'
    gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${GSA} --role 'roles/logging.logWriter'
    gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${GSA} --role 'roles/cloudprofiler.agent'
    gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${GSA} --role 'roles/clouddebugger.agent'
    gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${GSA} --role 'roles/errorreporting.writer'
    gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${GSA} --role 'roles/artifactregistry.reader'
done
