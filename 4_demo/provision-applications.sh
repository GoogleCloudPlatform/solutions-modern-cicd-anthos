#!/bin/bash -x

if [ -z ${GITLAB_HOSTNAME} ];then
  read -p "What is the GitLab hostname (i.e. my.gitlab.server)? " GITLAB_HOSTNAME
fi
if [ -z ${GITLAB_TOKEN} ];then
  read -p "What is the GitLab token? " GITLAB_TOKEN
fi

wget -q -O anthos-platform-cli https://storage.googleapis.com/solutions-public-assets/anthos-platform-cli/v0.5.0/anthos-platform-cli-v0.5.0-linux-amd64
chmod +x anthos-platform-cli

SERVICES="hipster-loadgenerator hipster-shop hipster-frontend petabank"

# Install Hipster Shop app (by microservice) and Petabank app
for service in ${SERVICES}; do
  APP_DEPLOYMENT="${service}-app"
  APP_EXISTS="$(kubectl get deployment ${APP_DEPLOYMENT} -n ${service})"
  if [ -z ${APP_EXISTS} ]; then
    ./anthos-platform-cli add app --name ${service} --gitlab-hostname ${GITLAB_HOSTNAME} --gitlab-token ${GITLAB_TOKEN} --template-name golang-template
  fi
done
