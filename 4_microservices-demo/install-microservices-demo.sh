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

if [ -z ${GITLAB_TOKEN} ];then
  read -p "What is the GitLab token? " GITLAB_TOKEN
fi

anthos-platform-cli add app --gitlab-insecure --name microservices-demo --gitlab-hostname ${GITLAB_HOSTNAME} \
    --gitlab-token ${GITLAB_TOKEN} --template-name golang-template

git -c http.sslVerify=false clone https://root:${GITLAB_TOKEN}@${GITLAB_HOSTNAME}/microservices-demo/microservices-demo.git microservices-demo-clone
cd microservices-demo-clone
git rm -r Dockerfile main.go skaffold.yaml k8s
mkdir hydrated-manifests
curl -o hydrated-manifests/stg.yaml https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml
# workaround for b/148377817 -- gke-deploy doesn't like a yaml file finishing with "---"
sed -i '$ d' hydrated-manifests/stg.yaml
cp hydrated-manifests/stg.yaml hydrated-manifests/prod.yaml
cat <<EOF >.gitlab-ci.yml
include:
- project: 'platform-admins/shared-ci-cd'
  file: 'cd/push-manifests.yaml'

stages:
  - push-manifests
EOF
git add .
git commit -m "Removing template and adding microservices-demo app"
git push
cd ..