#!/bin/bash -xe

if [ -z ${GITLAB_HOSTNAME} ];then
  read -p "What is the GitLab hostname (i.e. my.gitlab.server)? " GITLAB_HOSTNAME
fi

read -p "What is the new app's name? " APP_NAME
read -p "What is the repository group runner registration token? " RUNNER_REGISTRATION_TOKEN

NAMESPACE_DIR=../namespaces/managed-apps/${APP_NAME}
cp -a _namespace-template ${NAMESPACE_DIR}

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