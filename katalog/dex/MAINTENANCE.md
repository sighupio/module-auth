# Dex Package Maintenance Guide

To update the Dex package, follow the next steps.

Run the following commands:

```bash
helm repo add dex https://charts.dexidp.io
helm repo update
helm template dex dex/dex -n kube-system --values MAINTENANCE.values.yaml > dex-built.yml
```

With the `dex-built.yml` file, check differences with the current `deploy.yml` file and change accordingly.

## Customizations

What was customized (what differs from the helm template command):

- Simplified the labels
- Kept config volume mounted at `/etc/dex/cfg` (now chart default is `/etc/dex`) to allow other volumes under `/etc/dex/` (e.g. TLS CA at `/etc/dex/tls/`)
- Changed metrics port name from `telemetry` to `metrics`
- Simplified container command
- Changed configuration path
- Added resources and limits
- Added interval `30s` to ServiceMonitor
- Removed secret, since it's custom for each dex deploy
- Changed the themes and templates with custom branding
- Added securityContext configuration to be compliant with the `restricted` PSS. You should not see differences in the diff.

## How to customize the frontend templates

To customize the frontend templates, find and edit the files under the folder `web/templates`, if you need to just change the styles, edit the files under `web/themes/{light, dark}/styles.css`.

Then, to apply the changes, run the following command:

```bash
tar -czf web.tar.gz -C web .
```
