# Gangplank

<!-- <KFD-DOCS> -->

Gangplank is an application that can be used to easily enable authentication flows via OIDC for a Kubernetes cluster.

Kubernetes supports OpenID Connect Tokens as a way to identify users who access the cluster. Gangplank allows users to self-configure their kubectl configuration in a few short steps.

> ℹ️ Learn more about Gangplank in the [official repository](https://github.com/sighupio/gangplank) and in the [official documentation](https://github.com/sighupio/gangplank/blob/main/docs/README.md).

## Requirements

- Kubernetes >= `1.18.0`
- Kustomize = `v3.5.3`

## Image repository and tag

- Gangplank repository: <https://github.com/sighupio/gangplank>
- Gangplank container image: `registry.sighup.io/fury/gangplank:1.1.1`

## Configuration

Gangplank is configured using a `gangplank.yml` file. You can find a [sample configuration file here](example/gangplank.yml).

Notice that to enable Gangplank to communicate with Dex you need to add the required configuration under `staticClients` section.

Once you have written your configuration file, create a Kubernetes secret named `gangplank` in the `kube-system` namespace with the contents of the configuration file under the `gangplank.yml` key.

> ℹ️ We recommend you do this using Kustomize, either with a `secretGenerator` or as a resource.

The `gangplank` secret will then be mounted by the deployment as a volume in the right path.

## Deployment

Once you have created the configuration file, you can deploy Gangplank by running the following command in the folder of this package:

```shell
kustomize build | kubectl apply -f -
```

## License

For license details please see [LICENSE](https://sighup.io/fury/license)

<!-- </KFD-DOCS> -->
