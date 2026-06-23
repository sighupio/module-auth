<!-- markdownlint-disable MD033 -->
<h1 align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/sighupio/distribution/refs/heads/main/docs/assets/white-logo.png">
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/sighupio/distribution/refs/heads/main/docs/assets/black-logo.png">
  <img alt="Shows a black logo in light color mode and a white one in dark color mode." src="https://raw.githubusercontent.com/sighupio/distribution/refs/heads/main/docs/assets/white-logo.png">
</picture><br/>
  Auth Module
</h1>
<!-- markdownlint-enable MD033 -->

![Release](https://img.shields.io/badge/Latest%20Release-v0.7.0-blue)
![License](https://img.shields.io/github/license/sighupio/module-auth?label=License)
![Slack](https://img.shields.io/badge/slack-@kubernetes/fury-yellow.svg?logo=slack&label=Slack)

<!-- <SD-DOCS> -->

**Auth Module** provides authentication and access management for [SIGHUP Distribution (SD)][kfd-repo].

If you are new to SD please refer to the [official documentation][kfd-docs] on how to get started with SD.

## Overview

**Auth Module** uses CNCF recommended, Cloud Native projects, such as the [Dex][dex-repo] identity provider, and [Pomerium][pomerium-repo] as an identity-aware proxy to enable secure access to internal applications.

## Packages

The following packages are included in Auth Module:

| Package                        | Version   | Description                                                               |
| ------------------------------ | --------- | ------------------------------------------------------------------------- |
| [Pomerium](katalog/pomerium)   | `v0.32.7` | Identity-aware proxy that enables secure access to internal applications. |
| [Dex](katalog/dex)             | `v2.45.1` | Dex is a Federated OpenID Connect Provider.                               |
| [Gangplank](katalog/gangplank) | `v1.2.0`  | Enable authentication flows via OIDC for a Kubernetes cluster.            |

Click on each package to see its full documentation.

## Compatibility

| Kubernetes Version |   Compatibility    | Notes            |
| ------------------ | :----------------: | ---------------- |
| `1.29.x`           | :white_check_mark: | No known issues. |
| `1.30.x`           | :white_check_mark: | No known issues. |
| `1.31.x`           | :white_check_mark: | No known issues. |
| `1.32.x`           | :white_check_mark: | No known issues. |
| `1.33.x`           | :white_check_mark: | No known issues. |
| `1.34.x`           | :white_check_mark: | No known issues. |
| `1.35.x`           | :white_check_mark: | No known issues. |

Check the [compatibility matrix][compatibility-matrix] for additional information about previous releases of the modules.

## Usage

**Auth Module** is part of SIGHUP Distribution (SD) and is deployed automatically by [`furyctl`][furyctl-repo] when you create or update a cluster. You don't need to download, vendor or install its packages manually.

### Configuration

The module is deployed with sensible defaults. Configuration is **optional**: you can customize its packages under `spec.distribution.modules.auth` in your `furyctl.yaml`. If you omit the block, the defaults are applied.

```yaml
apiVersion: kfd.sighup.io/v1alpha2
kind: KFDDistribution
spec:
  distribution:
    modules:
      auth:
        baseDomain: example.dev
        provider:
          type: sso
        dex:
          connectors:
            - type: ldap
              id: ldap
              name: LDAP
              # connector-specific configuration
        pomerium: {}
```

See the configuration reference for your cluster kind for the full list of available options: [EKSCluster][schema-reference-eks], [KFDDistribution][schema-reference-kfd] or [OnPremises][schema-reference-onprem].

To install SD from scratch, follow the [Getting started][getting-started] guide.

<!-- Links -->

[kfd-repo]: https://github.com/sighupio/distribution
[furyctl-repo]: https://github.com/sighupio/furyctl
[kfd-docs]: https://docs.sighup.io/docs/distribution/
[pomerium-repo]: https://github.com/pomerium/pomerium
[dex-repo]: https://github.com/dexidp/dex
[schema-reference-eks]: https://docs.sighup.io/docs/reference/ekscluster#specdistributionmodulesauth
[schema-reference-kfd]: https://docs.sighup.io/docs/reference/kfddistribution#specdistributionmodulesauth
[schema-reference-onprem]: https://docs.sighup.io/docs/reference/onpremises#specdistributionmodulesauth
[getting-started]: https://docs.sighup.io/docs/getting-started/
[compatibility-matrix]: https://github.com/sighupio/module-auth/blob/main/docs/COMPATIBILITY_MATRIX.md

<!-- </SD-DOCS> -->

<!-- <FOOTER> -->

## Contributing

Before contributing, please read first the [Contributing Guidelines](https://github.com/sighupio/distribution/blob/main/docs/CONTRIBUTING.md).

### Reporting Issues

In case you experience any problem with the module, please [open a new issue](https://github.com/sighupio/module-auth/issues/new/choose).

## License

This module is open-source and it's released under the following [LICENSE](LICENSE).

<!-- </FOOTER> -->
