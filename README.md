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

![Release](https://img.shields.io/badge/Latest%20Release-v0.5.0-blue)
![License](https://img.shields.io/github/license/sighupio/module-auth?label=License)
![Slack](https://img.shields.io/badge/slack-@kubernetes/fury-yellow.svg?logo=slack&label=Slack)

<!-- <KFD-DOCS> -->

**Auth Module** provides Authentication Management for [SIGHUP Distribution (SD)][skd-repo].

If you are new to SD please refer to the [official documentation][skd-docs] on how to get started with the distribution.

## Overview

**Auth Module** uses CNCF recommended, Cloud Native projects, such as the [Dex][dex-repo] identity provider, and [Pomerium][pomerium-repo] as an identity-aware proxy to enable secure access to internal applications.

## Packages

Auth Module provides the following packages:

| Package                        | Version   | Description                                                               |
| ------------------------------ | --------- | ------------------------------------------------------------------------- |
| [Pomerium](katalog/pomerium)   | `v0.28.0` | Identity-aware proxy that enables secure access to internal applications. |
| [Dex](katalog/dex)             | `v2.42.0` | Dex is a Federated OpenID Connect Provider.                               |
| [Gangplank](katalog/gangplank) | `v1.1.0`  | Enable authentication flows via OIDC for a kubernetes cluster.            |

## Compatibility

| Kubernetes Version |   Compatibility    | Notes            |
| ------------------ | :----------------: | ---------------- |
| `1.29.x`           | :white_check_mark: | No known issues. |
| `1.30.x`           | :white_check_mark: | No known issues. |
| `1.31.x`           | :white_check_mark: | No known issues. |
| `1.32.x`           | :white_check_mark: | No known issues. |

Check the [compatibility matrix][compatibility-matrix] for additional information on previous releases of the modules.

## Usage


> [!NOTE]
> Instructions below are for deploying the module using furyctl legacy, that required manual intervention.
>
> Latest versions of furyctl automate the whole process and it is recommended to use the latest version of furyctl instead.

### Prerequisites

| Tool                        | Version   | Description                                                                                                                                                    |
| --------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [furyctl][furyctl-repo]     | `>=0.6.0` | The recommended tool to download and manage SD modules and their packages. To learn more about `furyctl` read the [official documentation][furyctl-repo].     |
| [kustomize][kustomize-repo] | `>=3.5.0` | Packages are customized using `kustomize`. To learn how to create your customization layer with `kustomize`, please refer to the [repository][kustomize-repo]. |

### Deployment with legacy furyctl

1. List the packages you want to deploy and their version in a `Furyfile.yml`:

```yaml
versions:
  auth: "v0.5.0"
bases:
  - name: auth/pomerium
  - name: auth/dex
  - name: auth/gangplank
```

> See `furyctl` [documentation][furyctl-repo] for additional details about `Furyfile.yml` format.

2. Execute `furyctl vendor -H` to download the packages

3. Inspect the download packages under `./vendor/katalog/auth/`.

4. Define a `kustomization.yaml` that includes the `./vendor/katalog/auth` directory as a resource.

```yaml
resources:
  - ./vendor/katalog/auth/pomerium
  - ./vendor/katalog/auth/dex
  - ./vendor/katalog/auth/gangplank
```

5. Create the configuration file for Dex ([here's an LDAP-based example](katalog/dex/config.yml)) and add it as a secret to the `kustomization.yaml` file, like this:

```yaml
secretGenerator:
  - name: dex
    namespace: kube-system
    files:
      - config.yml=./secrets/dex/config.yml
```

> ℹ️ read more on [Dex's readme](katalog/dex/README.md).

⛔️ Before proceeding, follow the instructions in [Pomerium's package readme](katalog/pomerium/README.md) and [Gangplank's readme](katalog/gangplank/README.md) to configure them.

6. Finally, to deploy the module to your cluster, execute:

```bash
kustomize build . | kubectl apply -f -
```

### Monitoring

SD Auth module integrates out-of-the-box with SD's Monitoring module. Providing metrics and dashboards to visualize the status of its components.

In particular:

- Dex exposes standard Go adapter metrics, the metrics are automatically scrapped by Prometheus when using SD Monitoring module but there are no Grafana dashboards nor alerts defined.
- Pomerium exposes several metrics about Pomerium itself and its underlying envoy proxy. Metrics are scrapped automatically by Prometheus and 2 Grafana dashboards are available with the `pomerium` tag when using SD Monitoring module. Here are some screenshots:

<!-- markdownlint-disable MD033 -->

<a href="docs/images/screenshots/pomerium-dashboard.png"><img src="docs/images/screenshots/pomerium-dashboard.png" width="250"/></a>
<a href="docs/images/screenshots/pomerium-envoy-dashboard.png"><img src="docs/images/screenshots/pomerium-envoy-dashboard.png" width="250"/></a>

<!-- markdownlint-enable MD033 -->

### Screenshots

<!-- markdownlint-disable MD033 -->

- Dex Login:

<a href="docs/images/screenshots/dex.png"><img src="docs/images/screenshots/dex.png" width="250"/></a>

- Pomerium 403 not authorized error screen:

<a href="docs/images/screenshots/pomerium-403.png"><img src="docs/images/screenshots/pomerium-403.png" width="250"/></a>

- Pomerium user profile screen:

<a href="docs/images/screenshots/pomerium-userprofile.png"><img src="docs/images/screenshots/pomerium-userprofile.png" width="250"/></a>

<!-- markdownlint-enable MD033 -->

<!-- Links -->

[furyctl-repo]: https://github.com/sighupio/furyctl
[skd-repo]: https://github.com/sighupio/distribution
[kustomize-repo]: https://github.com/kubernetes-sigs/kustomize
[skd-docs]: https://docs.kubernetesfury.com/docs/distribution/
[compatibility-matrix]: https://github.com/sighupio/module-auth/blob/master/docs/COMPATIBILITY_MATRIX.md
[pomerium-repo]: https://github.com/pomerium/pomerium
[dex-repo]: https://github.com/dexidp/dex

<!-- </KFD-DOCS> -->

<!-- <FOOTER> -->

## Contributing

Before contributing, please read first the [Contributing Guidelines](docs/CONTRIBUTING.md).

### Reporting Issues

In case you experience any problems with the module, please [open a new issue](https://github.com/sighupio/module-auth/issues/new/choose).

## License

This module is open-source and it's released under the following [LICENSE](LICENSE)

<!-- </FOOTER> -->
