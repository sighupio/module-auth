# Dex

<!-- <KFD-DOCS> -->

Dex is an identity service that uses OpenID Connect to drive authentication for other apps.

You can use Dex for example to provide OIDC authentication using users from an LDAP backend.

> ℹ️ Learn more about Dex in [the official documentation](https://dexidp.io/docs/getting-started/).

## Requirements

- Kubernetes >= `1.24.0`
- Kustomize >= `v3`

## Image repository and tag

- Dex repository: <https://github.com/dexidp/dex>
- Dex container image: `registry.sighup.io/fury/dexidp/dex:v2.44.0`

## Configuration

Dex is deployed with the following default configuration:

- Replica number: `1`
- Listens on port `5556`
- Resource limits are `250m` for CPU and `200Mi` for memory

Dex is configured using a `config.yml` file. You can get [a sample file from the official docs](https://github.com/dexidp/dex/blob/v2.20.0/examples/config-dev.yaml) or check out the [provided LDAP-based example configuration file](example/config.yml)

Once you have written the configuration file for your environment, create a Kubernetes secret named `dex` in the `kube-system` namespace with the contents of the file under the `config.yml` key.

> ℹ️ We recommend you do this using Kustomize, either with a `secretGenerator` or as a resource.

The `dex` secret will then be mounted by the deployment as a volume in the right path.

## Deployment

Once you have created the configuration file, you can deploy Dex by running the following command in the folder of this package:

```shell
kustomize build | kubectl apply -f -
```

<!-- </KFD-DOCS> -->
