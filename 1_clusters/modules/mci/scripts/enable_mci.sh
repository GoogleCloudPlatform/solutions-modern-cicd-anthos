#!/bin/bash -xe
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

set -e

if [ "$#" -lt 2 ]; then
    >&2 echo "Not all expected arguments set."
    exit 1
fi

PROJECT_ID=$1
CLUSTER_NAME=$2

gcloud alpha container hub ingress enable \
  --config-membership=projects/${PROJECT_ID}/locations/global/memberships/${CLUSTER_NAME} --project ${PROJECT_ID} || true

# ingress enabling can timeout after 2 minutes, but still be OK, validate accordingly
for i in {1..30}; do
  RESULT=$(gcloud alpha container hub ingress describe --project ${PROJECT_ID} --format="value(featureState.details.code)")
  if [ ${RESULT} = "OK" ]; then
    break;
  fi
  if [[ ${i} = 30 && ${RESULT} != "OK" ]]; then
    exit 1
  fi
  sleep 10
done
