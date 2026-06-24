# Pomerium

<!-- <SD-DOCS> -->

## Overview

Pomerium is an identity-aware proxy that enables secure access to internal applications. It provides a standardized way to add access control to applications regardless of whether the application itself has authorization or authentication baked in. In the Auth Module it sits in front of internal ingresses and delegates authentication to Dex.

## Upstream project

This package is based on the upstream [Pomerium][pomerium-github].

## Deployment

This package is deployed as part of **Auth Module** when you create a cluster with `furyctl`.

You can customize it under `spec.distribution.modules.auth.pomerium` in your `furyctl.yaml`. See the [module documentation](../../README.md) and the configuration reference ([EKSCluster][schema-reference-eks], [KFDDistribution][schema-reference-kfd], [OnPremises][schema-reference-onprem]) for the available options.

<!-- Links -->

[pomerium-github]: https://github.com/pomerium/pomerium
[schema-reference-eks]: https://docs.sighup.io/docs/reference/ekscluster#specdistributionmodulesauth
[schema-reference-kfd]: https://docs.sighup.io/docs/reference/kfddistribution#specdistributionmodulesauth
[schema-reference-onprem]: https://docs.sighup.io/docs/reference/onpremises#specdistributionmodulesauth

<!-- </SD-DOCS> -->

## License

For license details please see [LICENSE](../../LICENSE)
