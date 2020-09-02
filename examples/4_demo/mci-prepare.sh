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
  read -p "What is the GitLab token? " GITLAB_TOKEN
fi

rm -rf anthos-config-management
git -c http.sslVerify=false clone https://root:${GITLAB_TOKEN}@${GITLAB_HOSTNAME}/platform-admins/anthos-config-management.git
cd anthos-config-management

PETABANK_NAMESPACE=namespaces/managed-apps/petabank

pushd ${PETABANK_NAMESPACE}
  cp ../../../templates/petabank/multiclusteringress.yaml ./
  cp ../../../templates/petabank/multiclusterservice.yaml ./
  cp ../../../templates/petabank/network-policy-gcp-l7.yaml ./
popd

git add .
git commit -m "Setup MCI and Network Policy for MCI"
git -c http.sslVerify=false push -u origin master
