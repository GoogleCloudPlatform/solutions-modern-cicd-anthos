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
kpt cfg list-setters cicd_gitlab
kpt cfg set cicd_gitlab project-id A_PROJECT
kpt cfg set cicd_gitlab namespace A_NAMESPACET
```

### Apply the package

Create the SQLDatabase secret:

```
kubectl -n A_NAMESPACE create secret generic gitlab-db-password --from-literal password=<PASSWORD>
```

Initialize and apply the package:

```
kpt live init cicd_gitlab
kpt live apply cicd_gitlab
```
