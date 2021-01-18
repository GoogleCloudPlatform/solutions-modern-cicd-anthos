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

rm -rf anthos-config-management
git -c http.sslVerify=false clone https://root:${GITLAB_TOKEN}@${GITLAB_HOSTNAME}/platform-admins/anthos-config-management.git
cd anthos-config-management

BOUTIQUE_NAMESPACE=namespaces/managed-apps/online-boutique
PETABANK_NAMESPACE=namespaces/managed-apps/petabank
FRONTEND_NAMESPACE=namespaces/managed-apps/online-boutique-frontend

pushd ${BOUTIQUE_NAMESPACE}
  OB_ALLOW_FRONTEND=$(grep -e "name: allow-online-boutique-frontend" network-policy.yaml)
  if [ -z "${OB_ALLOW_FRONTEND}" ]; then
    rm network-policy.yaml
    cp ../../../templates/online-boutique/network-policy.yaml ./
  else
    echo "Network Policy already allows Online Boutique's Frontend traffic"
  fi
popd

pushd ${PETABANK_NAMESPACE}
  PB_ALLOW_FRONTEND=$(grep -e "name: allow-online-boutique-frontend" network-policy.yaml)
  if [ -z "${PB_ALLOW_FRONTEND}" ]; then
    rm network-policy.yaml
    cp ../../../templates/petabank/network-policy.yaml ./
  else
    echo "Network Policy already allows Online Boutique's Frontend traffic"
  fi
popd

pushd ${FRONTEND_NAMESPACE}
  FE_ALLOW_EXTERNAL_WEB=$(grep -e "name: allow-external-web" network-policy.yaml)
  if [ -z "${FE_ALLOW_EXTERNAL_WEB}" ]; then
    rm network-policy.yaml
    cp ../../../templates/online-boutique-frontend/network-policy.yaml ./
  else
    echo "Network Policy already allows external web traffic"
  fi
popd

if [ -z "${OB_ALLOW_FRONTEND}" ] || [ -z "${PB_ALLOW_FRONTEND}" ] || [ -z "${FE_ALLOW_EXTERNAL_WEB}" ]; then
  git add .
  git commit -m "Setup Network Policies for Online Boutique and Petabank"
  git -c http.sslVerify=false push -u origin master
else
  echo "No configuration changes needeed."
fi
