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
read -s -p "What is the access token? " GITLAB_TOKEN
fi

REPOS="anthos-config-management shared-kustomize-bases shared-ci-cd kustomize-docker kaniko-docker golang-template golang-template-env java-template java-template-env"
CLUSTERS="prod-us-central1 prod-us-east1 staging-us-central1"
pushd gitlab-repos
  # Create SSH keys so ACM syncers can read from the repos
  mkdir -p ../../ssh-keys
  pushd ../../ssh-keys
    for repo in ${REPOS}; do
       test -f ${repo} || ssh-keygen -f ${repo} -N ''
    done
    for cluster in ${CLUSTERS}; do
       test -f ${cluster} || ssh-keygen -f ${cluster} -N ''
    done
  popd
  terraform init
  terraform plan -var gitlab_token=${GITLAB_TOKEN} -var gitlab_hostname=${GITLAB_HOSTNAME}
  if [ -z ${TERRAFORM_AUTO_APPROVE} ]; then
    terraform apply -var gitlab_token=${GITLAB_TOKEN} -var gitlab_hostname=${GITLAB_HOSTNAME}
  else
    terraform apply -auto-approve -var gitlab_token=${GITLAB_TOKEN} -var gitlab_hostname=${GITLAB_HOSTNAME}
  fi
popd

# TODO: Don't hardcode the number of repos, list them all first
for i in `seq 1 9`; do
  curl --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" -X PUT --form 'shared_runners_enabled=true' https://${GITLAB_HOSTNAME}/api/v4/projects/$i
done

pushd ../starter-repos
  for repo in ${REPOS}; do
    pushd ${repo}
      export GIT_SSH_COMMAND="ssh -o \"StrictHostKeyChecking=no\" -i ../../ssh-keys/${repo}"
      rm -rf .git
      git init
      git remote add origin git@${GITLAB_HOSTNAME}:platform-admins/${repo}.git
      # Check if the repo has already been pushed to GitLab, if so skip this part.
      if ! git ls-remote --exit-code --heads origin master; then
        if [ "${repo}" == "golang-template" ] || [ "${repo}" == "java-template" ]; then
          sed -i.bak "s/GITLAB_HOSTNAME/${GITLAB_HOSTNAME}/g" k8s/stg/kustomization.yaml
          sed -i.bak "s/GITLAB_HOSTNAME/${GITLAB_HOSTNAME}/g" k8s/prod/kustomization.yaml
          sed -i.bak "s/GITLAB_HOSTNAME/${GITLAB_HOSTNAME}/g" k8s/dev/kustomization.yaml
          rm k8s/stg/kustomization.yaml.bak
          rm k8s/prod/kustomization.yaml.bak
          rm k8s/dev/kustomization.yaml.bak
        fi
        if [ "${repo}" == "anthos-config-management" ]; then
          sed -i.bak "s/GITLAB_HOSTNAME/${GITLAB_HOSTNAME}/g" namespaces/acm-tests/gitlab-runner-configmap-per-cluster.yaml
          rm namespaces/acm-tests/gitlab-runner-configmap-per-cluster.yaml.bak
        fi
        git add .
        git commit -m "Initial commit"
        git push origin master
      fi
    popd
  done
popd