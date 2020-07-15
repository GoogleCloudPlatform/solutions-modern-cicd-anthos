Anthos CI/CD clusters layer
==================================================

# NAME

  1_clusters

# SYNOPSIS

To apply the package:

    kubectl apply -R -f 1_clusters/

To edit the package:

    kpt cfg list-setters 1_clusters/
    kpt cfg set 1_clusters/ SETTER VALUE

# Description

The `1_clusters` package creates 1 dev, 1 staging, and 2 prod GKE clusters within the VPC network created in the [foundation package](../0_foundation/). To apply this package, you need to first apply the foundation package.

# SEE ALSO

[0_foundation](../0_foundation/) package