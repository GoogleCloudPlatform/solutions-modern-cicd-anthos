Anthos CI/CD clusters layer
==================================================

# NAME

  cicd_clusters

# SYNOPSIS

To apply the package:

    kubectl apply -R -f cicd_clusters

To edit the package:

    kpt cfg list-setters cicd_clusters/
    kpt cfg set cicd_clusters/ SETTER VALUE

# Description

The `cicd_clusters` package creates 1 dev, 1 staging, and 2 prod GKE clusters within the VPC network created in the [foundation package](../0_foundation/). To apply this package, you need to first apply the foundation package.

# SEE ALSO

[0_foundation](../0_foundation/) package
