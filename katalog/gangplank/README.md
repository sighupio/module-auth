# Gangplank

<!-- <SD-DOCS> -->

## Overview

Gangplank is an application that enables authentication flows via OIDC for a Kubernetes cluster. Kubernetes supports OpenID Connect tokens to identify users who access the cluster, and Gangplank lets users self-configure their `kubectl` configuration in a few short steps using the cluster's Dex provider.

## Upstream project

This package is based on the upstream [Gangplank][gangplank-github].

## Deployment

This package is deployed as part of **Auth Module** when you create a cluster with `furyctl`.

You can customize it under `spec.distribution.modules.auth` in your `furyctl.yaml`. See the [module documentation](../../README.md) and the configuration reference ([EKSCluster][schema-reference-eks], [KFDDistribution][schema-reference-kfd], [OnPremises][schema-reference-onprem]) for the available options.

<!-- Links -->

[gangplank-github]: https://github.com/sighupio/gangplank
[schema-reference-eks]: https://docs.sighup.io/docs/reference/ekscluster#specdistributionmodulesauth
[schema-reference-kfd]: https://docs.sighup.io/docs/reference/kfddistribution#specdistributionmodulesauth
[schema-reference-onprem]: https://docs.sighup.io/docs/reference/onpremises#specdistributionmodulesauth

<!-- </SD-DOCS> -->

## License

For license details please see [LICENSE](../../LICENSE)
