# Auth Module Release vTBD

Welcome to the latest release of the Auth module for the SIGHUP Distribution.

This release updates the package versions of Gangplank to the latest available.

## Included packages

| Package     | Current Version                                                        | Previous Version |
| ----------- | ---------------------------------------------------------------------- | ---------------- |
| `dex`       | [`v2.42.0`](https://github.com/dexidp/dex/releases/tag/v2.42.0)        | `v2.41.1`        |
| `gangplank` | [`v1.1.1`](https://github.com/sighupio/gangplank/releases/tag/v1.1.1)  | `v1.1.0`         |
| `pomerium`  | [`v0.28.0`](https://github.com/pomerium/pomerium/releases/tag/v0.28.0) | `v0.27.1`        |

## Update Guide 🦮

### Process

To upgrade this module from `v0.5.0` to `vTBD`, you need to download this new version, then apply the `kustomize` project. No further action is required.

```bash
kustomize build | kubectl apply -f -
```
