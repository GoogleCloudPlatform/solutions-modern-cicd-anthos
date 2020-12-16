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

if [ "$#" -lt 3 ]; then
    >&2 echo "Not all expected arguments set."
    exit 1
fi

CLUSTER_LOCATION=$1
CLUSTER_NAME=$2
SERVICE_ACCOUNT_KEY=$3

#write temp key, cleanup at exit
tmp_file=$(mktemp)
# shellcheck disable=SC2064
trap "rm -rf $tmp_file" EXIT
echo "${SERVICE_ACCOUNT_KEY}" | base64 --decode > "$tmp_file"

gcloud container hub memberships register "${CLUSTER_NAME}" --gke-cluster="${CLUSTER_LOCATION}"/"${CLUSTER_NAME}" --service-account-key-file="${tmp_file}" --quiet