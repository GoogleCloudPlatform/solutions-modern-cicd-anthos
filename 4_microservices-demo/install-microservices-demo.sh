#!/bin/bash -xe

if [ -z ${GITLAB_HOSTNAME} ];then
  read -p "What is the GitLab hostname (i.e. my.gitlab.server)? " GITLAB_HOSTNAME
fi

if [ -z ${GITLAB_TOKEN} ];then
  read -p "What is the GitLab token? " GITLAB_TOKEN
fi

wget -O anthos-platform-cli https://storage.googleapis.com/solutions-public-assets/anthos-platform-cli/v0.4.0/anthos-platform-cli-v0.4.0-linux-amd64
chmod +x anthos-platform-cli

./anthos-platform-cli add app --name microservices-demo --gitlab-hostname ${GITLAB_HOSTNAME} \
    --gitlab-token ${GITLAB_TOKEN} --template-name golang-template

git clone https://root:${GITLAB_TOKEN}@${GITLAB_HOSTNAME}/microservices-demo/microservices-demo.git microservices-demo-clone
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