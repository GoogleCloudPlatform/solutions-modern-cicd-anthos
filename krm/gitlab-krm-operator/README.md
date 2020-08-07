# Gitlab KRM Operator

  Gitlab KRM Operator is a kubernetes extension that implements Kubernetes style APIs for Gitlab resources.
  Currently it supports following APIs:

  - Groups
  - Projects
  - DeployKeys

# Prerequisites

  Before you begin installing this operator in a kubernetes cluster, you will need the following:

  - Kubernetes (v1.14+) cluster
  - Kustomize
  - Kubectl configured to talk to the kubernetes cluster
  - Gitlab Base API URL
  - Access Token to access the APIs

# Installation

  1. Edit the kustomization file to replace the Gitlab base API URL and Gitlab access token as shown below:

  ```yaml
namePrefix: gitlab-cnrm-
namespace: gitlab-cnrm-system
resources:
  - ...
secretGenerator:
  - name: gitlab-creds
    literals:
    - gitlab-token="GITLAB_ACCESS_TOKEN" <--- Put Gitlab access token here
configMapGenerator:
  - name: gitlab-config
    literals:
      - gitlab-base-url="GITLAB BASE API URL" <-- Put Gitlab API URL
  ```

  2. Run `kustomize build -o resources.yaml .` to hydrate the configuration and then run `kubectl apply -f resources.yaml` to apply it to the cluster.

  3. You can run `kubectl get -f resources.yaml`  to examine the resources.

  # Examples

  Examples below shows manifests for Gitlab group, project and deploy key resource. You can `kubectl apply -f <resource>` to create the resource.

  1. Example below shows Gitlab group resource.
  
  ```yaml
apiVersion: cnrm.gitlab.com/v1beta1
kind: Group
metadata:
  name: sunil-test-platform-admins
spec:
  path: sunil-test-platform-admins
  description: "An group of projects for Platform Admins"
  visibilityLevel: internal

  ```

  2. Example below shows Gitlab project resource. 

  ```yaml
apiVersion: cnrm.gitlab.com/v1beta1
kind: Project
metadata:
  name: sunil-test-anthos-config-management-1
spec:
  description: "Anthos Config Management repo"
  groupRef:
    name: sunil-test-platform-admins
  visibilityLevel: internal
  defaultBranch: master

  ```

  3. Example below shows Deploy key.

  ```yaml
apiVersion: cnrm.gitlab.com/v1beta1
kind: DeployKey
metadata:
  name: sunil-test-acm-prod-us-central1
spec:
  title: "Production us-central1 deploy key"
  projectRef:
    name: sunil-test-anthos-config-management-1
  key: "ssh-rsa your-public-key"
  ```
