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


if [ -z ${GITLAB_HOSTNAME} ];then
  read -p "What is the GitLab hostname (i.e. my.gitlab.server)? " GITLAB_HOSTNAME
fi

if [ -z ${APP_NAME} ];then
  read -p "What is the new app's name? " APP_NAME
fi

if [ -z ${RUNNER_REGISTRATION_TOKEN} ];then
  read -p "What is the repository group runner registration token? " RUNNER_REGISTRATION_TOKEN
fi

NAMESPACE_DIR=../namespaces/managed-apps/${APP_NAME}
mkdir -p ${NAMESPACE_DIR}
cp -a _namespace-template/* ${NAMESPACE_DIR}/

pushd ${NAMESPACE_DIR}
  # Set the APP_NAME
  sed -i s/APP_NAME/${APP_NAME}/g *

  # Set the Gitlab Hostname
  sed -i s/GITLAB_HOSTNAME/${GITLAB_HOSTNAME}/g *

  # Base64 encode the registration token so it can
  # be replaced in the Kubernetes secret
  RUNNER_REGISTRATION_TOKEN_BASE64=$(echo $RUNNER_REGISTRATION_TOKEN | base64)
  sed -i s/RUNNER_REGISTRATION_TOKEN_BASE64/$RUNNER_REGISTRATION_TOKEN_BASE64/ *
popd

echo "Created namespace ${APP_NAME} at ${NAMESPACE_DIR}"