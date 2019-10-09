#!/bin/bash

gcloud container clusters get-credentials anthos-platform-prod-central --region us-central1
kubectl config rename-context $(kubectl config current-context) prod-central

gcloud container clusters get-credentials anthos-platform-prod-east --region us-east1
kubectl config rename-context $(kubectl config current-context) prod-east

gcloud container clusters get-credentials anthos-platform-staging --region us-central1
kubectl config rename-context $(kubectl config current-context) staging

gcloud container clusters get-credentials anthos-platform-ci --region us-central1
kubectl config rename-context $(kubectl config current-context) ci

gcloud container clusters get-credentials gitlab --region us-central1
kubectl config rename-context $(kubectl config current-context) gitlab


for CONTEXT in prod-central prod-east staging ci; do
  kubectl config use-context ${CONTEXT}
  kubectl apply -f config-management-operator.yaml
  KEYNAME=${CONTEXT}-ssh
  mkdir -p ssh-keys
  ssh-keygen -t rsa -b 4096 -C "[${CONTEXT}]" \
     -N '' -f ssh-keys/${KEYNAME}
  kubectl delete secret git-creds --namespace=config-management-system || true
  kubectl create secret generic git-creds --namespace=config-management-system \
          --from-file=ssh=ssh-keys/${KEYNAME}
  GITLAB_ADDRESS=$(gcloud compute addresses describe gitlab --region us-central1 --format 'value(address)')
  export GITLAB_HOSTNAME=gitlab.${GITLAB_ADDRESS}.xip.io
  export CONTEXT=${CONTEXT}
  cat config-management.yaml.tpl | envsubst > config-management-${CONTEXT}.yaml
  kubectl apply -f config-management-${CONTEXT}.yaml
done

GITLAB_PASSWORD=$(kubectl get secrets gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d)
echo "Gitlab root password is: ${GITLAB_PASSWORD}"