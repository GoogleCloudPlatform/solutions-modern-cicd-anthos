# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this
project adheres to [Semantic Versioning](http://semver.org/).

## [0.4.0](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/compare/v0.3.1...v0.4.0) (2020-08-28)


### Features

* Broaden oauth scope to cloud-platform ([#56](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/56)) ([6eea966](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/6eea966f4ea4d5de2b5570f908ec756361ef8bcd))

### [0.3.1](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/compare/v0.3.0...v0.3.1) (2020-08-13)


### Bug Fixes

* Fixed typo in values.yaml.tpl which prevented cache from working on GCS. ([#52](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/52)) ([ba4d0df](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/ba4d0df929627c75d76d7da1ad33f165b7d1a8a9))
* Update to enable working with v4.2.4 of GitLab Helm Chart ([#55](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/55)) ([8dfded6](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/8dfded6d6c9fd507740ce3968614f46fa10e4454))

## [0.3.0](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/compare/v0.2.0...v0.3.0) (2020-07-16)


### Features

* Expose the K8s cluster info as outputs ([#50](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/50)) ([1ea4e88](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/1ea4e882d13b800ca213b89a27a134efc28d4afe))

## [0.2.0](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/compare/v0.1.1...v0.2.0) (2020-06-27)


### Features

* Optionally add random prefix to csql db instance ([#47](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/47)) ([8edb48c](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/8edb48ce868f0ca9374213aae767a363f03474a7))


### Bug Fixes

* Switch to helm3 and add tests ([#46](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/46)) ([6f4b9f7](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/6f4b9f745c3f5a51e018b47d1ade7f9d32c36630))
* terraform fmt, and fixing tf 0.12 warnings ([#42](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/42)) ([c3dd306](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/c3dd306bb46ed92cfac24be0ad7e680ae769f6dd))

### [0.1.1](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/compare/v0.1.0...v0.1.1) (2020-05-20)


### Bug Fixes

* Switch to using module for service activation and ensure ordering. ([ef2a316](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/ef2a3166a2746e6544c3c33f5aba7a19d5034765))

## [v0.1.0](https://github.com/terraform-google-modules/terraform-google-gke-gitlab/releases/tag/v0.1.0) - 2020-05-15
This is the initial module release.
