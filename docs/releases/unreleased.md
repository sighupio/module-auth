# Auth Module Release v0.6.0

Welcome to the latest release of the Auth module for the SIGHUP Distribution.

This release updates Pomerium to the latest version available upstream, bringing enhanced security features and improved functionality.

## Included packages

| Package     | Current Version                                                        | Previous Version |
| ----------- | ---------------------------------------------------------------------- | ---------------- |
| `dex`       | [`v2.42.0`](https://github.com/dexidp/dex/releases/tag/v2.42.0)        | `v2.42.0`        |
| `gangplank` | [`v1.1.1`](https://github.com/sighupio/gangplank/releases/tag/v1.1.1)  | `v1.1.1`         |
| `pomerium`  | [`v0.30.5`](https://github.com/pomerium/pomerium/releases/tag/v0.30.5) | `v0.28.0`        |

## Compatibility

This release adds support for Kubernetes 1.33.x while maintaining compatibility with previous versions (1.29.x - 1.32.x).

## Update Guide 🦮

### Process

To upgrade this module from `v0.5.1` to `v0.6.0`, you need to download this new version, then apply the `kustomize` project. No breaking changes or configuration updates are required.

```bash
kustomize build | kubectl apply -f -
```

#### Pomerium

Please pay attention, Pomerium v0.29.0 includes potentially breaking changes that depend on the target environment.

Basically, Pomerium v0.29.0 replaces all existing tracing methods with a new OpenTelemetry-based system:

- Enable seamless request tracing across multiple services with the new OTEL-based tracing system. Users can now easily configure and understand traces, with improved visibility into the flow of requests, even at low sample rates. All previously supported tracing methods are removed.

For more technical details check the upstream [release notes](https://github.com/pomerium/pomerium/releases/tag/v0.29.0).

### Notes

- Pomerium v0.29.0 has breaking changes that don't impact the module directly
- Existing policy and configuration files remain fully compatible
- All current features continue to work as expected