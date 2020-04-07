#!/bin/bash -x

SERVICES="hipster-loadgenerator hipster-shop hipster-frontend petabank"
gcloud container clusters get-credentials staging-us-central1 --region us-central1

echo "Deleting template deployments and services"
for service in ${SERVICES}; do
  export TEMPLATE_APP=${service}-app
  export TEMPLATE_APP_EXISTS=$(kubectl get deployment ${TEMPLATE_APP} -n ${service})
  if [ "${TEMPLATE_APP_EXISTS}" ]; then
    kubectl delete deployment ${TEMPLATE_APP} -n ${service} --now || true
    kubectl delete svc ${TEMPLATE_APP} -n ${service} || true
  fi
done
