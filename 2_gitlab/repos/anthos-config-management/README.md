# Anthos Configuration Management Directory

This is the root directory for Anthos Configuration Management.

See [our documentation](https://cloud.google.com/anthos-config-management/docs/repo) for how to use each subdirectory.

## Automated testing

You need to have a GitLab runner for this project in each cluster you want
to manage to test ACM's configuration.

### Setup

1. In this project, go to *Settings > CI / CD*.
1. Disable "Shared Runners" for this project.
1. Copy the runner registration token for this project.
1. On each cluster, run `kubectl -n acm-tests create secret generic gitlab-runner --from-literal=runner-registration-token=MY_TOKEN`
   where `MY_TOKEN` is the token you just copied.
1. In `clusterregistry`, create a Cluster and ClusterSelector for each of your clusters.
1. In ` namespaces/acm-tests/gitlab-runner-configmap-per-cluster.yaml`, create
   a ConfigMap for each of your clusters, with the right cluster selection
   annotation, and the right GitLab Runner tag.
1. In `.gitlab-ci.yml`, add a job for each cluster, modifying the tag each time.
