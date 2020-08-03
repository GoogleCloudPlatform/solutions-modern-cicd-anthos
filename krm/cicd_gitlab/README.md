# cicd_gitlab

## NAME

cicd_gitlab

## Description

Deploys GitLab on GCP.

## USAGE

### Fetch the package:

```
kpt pkg get https://github.com/GoogleCloudPlatform/solutions-modern-cicd-anthos.git/krm/cicd_gitlab@krm cicd_gitlab
```

### Customize the package:

```
kpt cfg cicd_gitlab list-setters
kpt cfg cicd_gitlab set project-id A_PROJECT
kpt cfg cicd_gitlab set namespace A_NAMESPACE
```

### Apply the package

```
kpt live init cicd_gitlab
kpt live apply cicd_gitlab
```
