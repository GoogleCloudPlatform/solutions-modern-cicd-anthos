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

# TODO: Check APPS environment variable, otherwise set APPS to default list
APPS="online-boutique-loadgen online-boutique online-boutique-frontend petabank"

gcloud container clusters get-credentials staging-us-west2 --region us-west2

echo "Deleting template deployments and services"
for appname in ${APPS}; do
  export TEMPLATE_APP=${appname}-app
  export TEMPLATE_APP_EXISTS=$(kubectl get deployment ${TEMPLATE_APP} -n ${appname})
  if [ "${TEMPLATE_APP_EXISTS}" ]; then
    kubectl delete deployment ${TEMPLATE_APP} -n ${appname} --now || true
    kubectl delete svc ${TEMPLATE_APP} -n ${appname} || true
    echo "Sleep for 1 minute to allow template app to delete from cluster"
    sleep 1m
  fi
done
