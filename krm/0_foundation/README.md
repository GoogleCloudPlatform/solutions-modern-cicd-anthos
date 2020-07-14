Anthos CI/CD foundation layer
==================================================

# NAME

  0_foundation

# SYNOPSIS

To apply the package:

    kubectl apply -R -f 0_foundation/

To edit the package:

    kpt cfg list-setters 0_foundation
    kpt cfg set 0_foundation SETTER VALUE

# Description

The `0_foundation` package creates a GCP VPC network and enables required Cloud Services.
To apply this package, you need to first
[install Config Connector](https://cloud.google.com/config-connector/docs/how-to/install-upgrade-uninstall)
and [configure the `Namespace`](https://cloud.google.com/config-connector/docs/concepts/namespaces-and-projects).

# SEE ALSO

* [Config Connector Overview](https://cloud.google.com/config-connector/docs/overview)
