# Dex

<!-- <SD-DOCS> -->

## Overview

Dex is an identity service that uses OpenID Connect to drive authentication for other apps. In the Auth Module it acts as the OIDC provider, federating authentication to upstream identity sources (for example an LDAP backend) so that users can sign in to internal applications and to the cluster.

## Upstream project

This package is based on the upstream [Dex][dex-github].

## Deployment

This package is deployed as part of **Auth Module** when you create a cluster with `furyctl`.

You can customize it under `spec.distribution.modules.auth.dex` in your `furyctl.yaml`. See the [module documentation](../../README.md) and the configuration reference ([EKSCluster][schema-reference-eks], [KFDDistribution][schema-reference-kfd], [OnPremises][schema-reference-onprem]) for the available options.

<!-- Links -->

[dex-github]: https://github.com/dexidp/dex
[schema-reference-eks]: https://docs.sighup.io/docs/reference/ekscluster#specdistributionmodulesauth
[schema-reference-kfd]: https://docs.sighup.io/docs/reference/kfddistribution#specdistributionmodulesauth
[schema-reference-onprem]: https://docs.sighup.io/docs/reference/onpremises#specdistributionmodulesauth

<!-- </SD-DOCS> -->

## License

For license details please see [LICENSE](../../LICENSE)
