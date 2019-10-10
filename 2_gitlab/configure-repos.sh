#!/bin/bash -xe

if [ -z ${GITLAB_HOSTNAME} ];then
  read -p "What is the GitLab hostname (i.e. my.gitlab.server)? " GITLAB_HOSTNAME
fi

if [ -z ${GITLAB_TOKEN} ];then
read -p "What is the access token? " GITLAB_TOKEN
fi

cat > python-gitlab.cfg <<EOF
[global]
default = anthos-platform
ssl_verify = true
timeout = 5

[anthos-platform]
url = https://$GITLAB_HOSTNAME
oauth_token = Fx8oJ4gGcxpBnZHXpxAA
api_version = 4
EOF

export GITLAB_CMD='docker run -v `pwd`/python-gitlab.cfg viglesiasce/python-gitlab:latest'

for i in `seq 1 7`;do
  $GITLAB_CMD project-update --shared-runners-enabled true --id $i
done