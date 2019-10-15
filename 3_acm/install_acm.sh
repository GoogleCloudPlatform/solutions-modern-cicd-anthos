#!/bin/bash -xe

if [ -z ${GITLAB_HOSTNAME} ];then
  read -p "What is the GitLab hostname (i.e. my.gitlab.server)? " GITLAB_HOSTNAME
fi

gcloud container clusters get-credentials anthos-platform-prod-central --region us-central1
! kubectl config delete-context prod-central
kubectl config rename-context $(kubectl config current-context) prod-central

gcloud container clusters get-credentials anthos-platform-prod-east --region us-east1
! kubectl config delete-context prod-east
kubectl config rename-context $(kubectl config current-context) prod-east

gcloud container clusters get-credentials anthos-platform-staging --region us-central1
! kubectl config delete-context staging
kubectl config rename-context $(kubectl config current-context) staging

for CONTEXT in prod-central prod-east staging; do
  kubectl config use-context ${CONTEXT}
  kubectl apply -f config-management-operator.yaml
  KEYNAME=${CONTEXT}
  kubectl delete secret git-creds --namespace=config-management-system || true
  kubectl create secret generic git-creds --namespace=config-management-system \
          --from-file=ssh=../ssh-keys/${KEYNAME}
  GITLAB_ADDRESS=$(gcloud compute addresses describe gitlab --region us-central1 --format 'value(address)')
  export GITLAB_HOSTNAME=${GITLAB_HOSTNAME}
  export CONTEXT=${CONTEXT}
  cat config-management.yaml.tpl | envsubst > config-management-${CONTEXT}.yaml
  kubectl apply -f config-management-${CONTEXT}.yaml
done
