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

See all the setters:

```
kpt cfg list-setters cicd_gitlab
```

`project-id` is required:

```
kpt cfg set cicd_gitlab project-id my-project
```

### Apply the package

Initialize and apply the package:

```
kpt live init cicd_gitlab
kpt live apply cicd_gitlab
```

Create the SQLDatabase secret:

```
kubectl -n gitlab create secret generic gitlab-db-password --from-literal password=<PASSWORD>
```
