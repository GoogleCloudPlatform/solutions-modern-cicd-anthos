# Overview

This is a sample application written in Java. In most cases, this should not be used
for development of a new application.

## Useage

Replace files (ex: pom.xml and src/ folders) to match the intended application's source.

## Critical Files

The following is a list of critical files utilized in the conventions for building
an Anthos application.

| File/Folder   |      Description      |  Required  |
|:-------------:|:----------------------|-----------:|
| Dockerfile :whale: |  File used to create the Docker image (built with kaniko) | :white_check_mark: |
| skaffold.yaml |  Used in local development to keep development environment in sync with changes. If not using skaffold, this file is optional (but recommended) |  :white_large_square: |
| .gitlab-ci.yml | CICD Pipeline setup to build to inherit the conventions for the development organization/ecosystem | :white_check_mark: |
| k8s/ | Folder containing the Kubernetes resource manifests for "dev", "stage" and "prod". Resource files are configured to use Kustomize during the CICD build. | :white_check_mark: |