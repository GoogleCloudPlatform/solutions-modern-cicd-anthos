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

if [ -z ${ACM_RUNNER_TOKEN} ]; then
  echo "Anthos Config Management needs dedicated GitLab CI runners."
  read -s -p "What is the runner registration token for ACM (see Settings > CI/CD > Runners in the anthos-config-management project)?" ACM_RUNNER_TOKEN
fi

CLUSTERS="prod-us-central1 prod-us-east1 staging-us-west2"

for CONTEXT in ${CLUSTERS}; do
  REGION=$(echo ${CONTEXT} | cut -d'-' -f 2-)
  gcloud container clusters get-credentials ${CONTEXT} --region ${REGION}
  ! kubectl config delete-context ${CONTEXT}  > /dev/null 2>&1
  kubectl config rename-context $(kubectl config current-context) ${CONTEXT}

  # We need to have this namespace before enabling ACM, because we need to create
  # a secret in it
  # Check it GitLab Runner is already running
  if ! kubectl get deployments -n acm-tests gitlab-runner; then
    kubectl delete ns acm-tests --wait=true || true
    kubectl create ns acm-tests
    kubectl -n acm-tests create secret generic gitlab-runner \
      --from-literal=runner-registration-token=${ACM_RUNNER_TOKEN}

    kubectl apply -f config-management-operator.yaml
    KEYNAME=${CONTEXT}
    kubectl delete secret git-creds --namespace=config-management-system > /dev/null 2>&1 || true
    kubectl create secret generic git-creds --namespace=config-management-system \
            --from-literal=ssh="$(gcloud secrets versions access latest --secret="gitlab-cluster-key-${KEYNAME}")"
    GITLAB_ADDRESS=$(gcloud compute addresses describe gitlab --region us-central1 --format 'value(address)')
    export GITLAB_HOSTNAME=${GITLAB_HOSTNAME}
    export CONTEXT=${CONTEXT}
    cat config-management.yaml.tpl | envsubst > config-management-${CONTEXT}.yaml
    kubectl apply -f config-management-${CONTEXT}.yaml
    rm config-management-${CONTEXT}.yaml
  # Runner is already installed, make sure the token is up to date
  # If not up to date, re-create the secret and restart the runner pod
  else
    export ACM_RUNNER_TOKEN_BASE64=$(echo ${ACM_RUNNER_TOKEN} | base64)
    export CURRENT_ACM_TOKEN_BASE64=$(kubectl get secret -n acm-tests gitlab-runner -o jsonpath='{.data.runner-registration-token}' || true)
    if [ "${ACM_RUNNER_TOKEN_BASE64}" != "${CURRENT_ACM_TOKEN_BASE64}" ];then
      kubectl -n acm-tests delete secret gitlab-runner --ignore-not-found=true
      kubectl -n acm-tests create secret generic gitlab-runner \
              --from-literal=runner-registration-token=${ACM_RUNNER_TOKEN}
      kubectl -n acm-tests delete pod -l app=gitlab-runner
    fi
  fi
done
