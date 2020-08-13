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

REPOS="anthos-config-management shared-kustomize-bases shared-ci-cd kustomize-docker kaniko-docker golang-template golang-template-env java-template java-template-env"
CLUSTERS="prod-us-central1 prod-us-east1 staging-us-west2"
# Create SSH keys so ACM syncers can read from the repos
# at base of 2_gitlab
export WORKINGDIR=$(pwd)
mkdir -p ${WORKINGDIR}/ssh-keys

pushd gitlab-repos
  # TODO: Convert this into Terraform using Google Cloud KMS
  pushd ${WORKINGDIR}/ssh-keys
    for repo in ${REPOS}; do
       test -f ${repo} || ssh-keygen -f ${repo} -N ''
    done
    for cluster in ${CLUSTERS}; do
       test -f ${cluster} || ssh-keygen -f ${cluster} -N ''
       # Create a secret with the private key
       gcloud secrets delete gitlab-cluster-key-${cluster} --quiet || true
       gcloud secrets create gitlab-cluster-key-${cluster} --replication-policy=automatic --data-file <(cat "${cluster}")
    done
  popd

  terraform init
  terraform plan -var gitlab_token=${GITLAB_TOKEN} -var ssh-key-path-base=${WORKINGDIR}/ssh-keys -out=terraform.tfplan
  terraform apply -auto-approve terraform.tfplan

  export GITLAB_HOSTNAME=$(terraform output gitlab_hostname)

  # TODO: Move into terraform sometime in the future, for now, forcefully delete in destroy
  gcloud secrets delete gitlab-user --quiet || true
  gcloud secrets create gitlab-user --replication-policy=automatic --data-file <(echo -n "root")
  gcloud secrets delete gitlab-password --quiet || true
  gcloud secrets create gitlab-password --replication-policy=automatic --data-file <(echo -n "${GITLAB_TOKEN}")
popd

# Enable shared runners on all repos so that the can build from the CI cluster
for i in `seq 1 $(echo ${REPOS} | wc -w)`; do
  # There are times during setup that the cert has not yet been received
  # Temporarily ignore the SSL validation check
  curl -k --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" -X PUT --form 'shared_runners_enabled=true' https://${GITLAB_HOSTNAME}/api/v4/projects/$i
done

pushd ./starter-repos
  for repo in ${REPOS}; do
    pushd ${repo}
      export GIT_SSH_COMMAND="ssh -o \"StrictHostKeyChecking=no\" -i ${WORKINGDIR}/ssh-keys/${repo}"
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
