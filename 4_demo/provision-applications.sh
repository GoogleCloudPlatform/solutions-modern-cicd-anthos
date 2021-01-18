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


if [ -z ${GITLAB_HOSTNAME} ];then
  read -p "What is the GitLab hostname (i.e. my.gitlab.server)? " GITLAB_HOSTNAME
fi
if [ -z ${GITLAB_TOKEN} ];then
  read -p "What is the GitLab token? " GITLAB_TOKEN
fi

# TODO: Check APPS environment variable, otherwise set APPS to default list
APPS="online-boutique-loadgen online-boutique online-boutique-frontend petabank"

# Install Online Boutique app (by microservice) and Petabank app
for appname in ${APPS}; do
  APP_DEPLOYMENT="${appname}-app"
  APP_EXISTS="$(kubectl get deployment ${APP_DEPLOYMENT} -n ${appname})"
  if [ -z ${APP_EXISTS} ]; then
    anthos-platform-cli add app --gitlab-insecure --name ${appname} --gitlab-hostname ${GITLAB_HOSTNAME} --gitlab-token ${GITLAB_TOKEN} --template-name golang-template
  fi
  echo "Sleep for 1 minute to allow template app to deploy to cluster so it can be deleted later"
  sleep 1m
done
