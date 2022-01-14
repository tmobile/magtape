# Advanced Install

We've tried to build a decent amount of flexibility into MagTape. While the simple installation method is great for demos and POC's, more care should be taken when deploying to Production type environments. The information in this document serves as general guidelines for what is possible, but is NOT a step by step guide. Some reading between the lines is required.

## Configuration Options

NOTE: The following environment variable are defined in the `magtape-env-cm.yaml` manifest and can be used to customize MagTape's behavior.

| Variable                            | Description                                                                                                                                                                        | Values                                                                  |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `FLASK_ENV`                         | The operation environment for Flask                                                                                                                                                | `production` or `development`                                           |
| `MAGTAPE_DENY_LEVEL`                | Controls the level of denial for checks. Please see section above on Deny Level                                                                                                    | `LOW`, `MED`, or `HIGH`                                                 |
| `MAGTAPE_LOG_LEVEL`                 | The log level to use                                                                                                                                                               | `INFO` or `DEBUG`                                                       |
| `MAGTAPE_CLUSTER_NAME`              | The name of the Kubernetes Cluster where the webhook is deployed                                                                                                                   | `test-cluster`                                                          |
| `MAGTAPE_K8S_EVENTS_ENABLED`        | Controls whether or not Kubernetes events are generated within the target namespace for policy failures                                                                            | `TRUE` or `FALSE`                                                       |
| `MAGTAPE_SLACK_ENABLED`             | Controls whether or not the webhook sends Slack notifications                                                                                                                      | `TRUE` or `FALSE`                                                       |
| `MAGTAPE_SLACK_PASSIVE`             | Controls whether or not Slack alerts are sent for checks that fail, but aren't denied due to the DENY_LEVEL setting                                                                | `TRUE` or `FALSE`                                                       |
| `MAGTAPE_SLACK_WEBHOOK_URL_BASE`    | **OPTIONAL** - Overrides the base domain (`hooks.slack.com`) for the Slack Incoming Webhook URL. Used for airgapped environments where a forwarding/proxying service may be needed | `slack-proxy.example.com`                                               |
| `MAGTAPE_SLACK_WEBHOOK_URL_DEFAULT` | The URL for the Slack Incoming Webhook.                                                                                                                                            | `https://hooks.slack.com/services/XXXXXXXX/XXXXXXXX/XXXXXXXXXXXXXXXXXX` |
| `MAGTAPE_SLACK_USER`                | The user the Slack alerts should be sent as                                                                                                                                        | `mtbot`                                                                 |
| `MAGTAPE_SLACK_ICON`                | The emoji to use for the user icon in the alert                                                                                                                                    | `:magtape:`                                                             |
| `OPA_BASE_URL`                      | The base URL used to contact the OPA API                                                                                                                                           | `http://localhost:8181`                                                 |
| `OPA_K8S_PATH`                      | The common path to reference all Kubernetes based OPA policies                                                                                                                     | `/v0/data/magtape`                                                      |

## Installation

MagTape can be setup to use [kustomize](https://kustomize.io) to handle config substitution and generating the YAML manifests to deploy to Kubernetes.

The kustomize layout uses overlays to allow for flexibility in configuration (ie. per environment (Development, Production, etc.) or per cluster substitutions)

You can find some generic examples of using kustomize overlays to manage per environment configuration in the following directories:

| DIRECTORY                     | DESCRIPTION                                    |
| ----------------------------- | ---------------------------------------------- |
| `deploy/manifests`            | The base YAML manifests                        |
| `deploy/overlays/development` | Development environment specific substitutions |
| `deploy/overlays/production`  | Production environment specific substitutions  |

Once the proper edits have been made you can generate the YAML manifests:

```shell
$ kustomize build deploy/overlays/development | kubectl -n <namespace> apply -f -
```

### Special Considerations

There are some configurations that will require a little more effort when not using the simple install process:

#### Policies

Polcies can be managed using the configMapGenerator option of Kustomize. You'll need to rearrange the `policies` directory as required by Kustomize (it needs to be relative to the base/overlay), and then add a snippet for to your overlay's `kustomization.yaml` similar to the following:

```yaml
configMapGenerator:
- name: policy-liveness-probe-check
  files:
    -   ../policies/policy-liveness-probe-check.rego
  options:
    labels:
      app: opa
      openpolicyagent.org/policy: rego
```

Generation config would need to be setup for each policy you would want to deploy

#### Others

NOTE: A TLS Cert and Key need to be generated for the Webhook. MagTape has an init container that can handle generating the required tls cert/key pair or you can BYOC ([Bring Your Own Cert](#bring-your-own-cert)). The init process uses the Kubernetes `CertificateSigningRequest` API to generate a certificate signed by the Kubernetes CA. The VWC (ValidatingWebhookConfiguration) is also deployed during the init process and the `caBundle` field is automatically populated based on the configuration supplied. The [VWC configuration](#vwc-template) is managed via a template in a configmap.

## Bring Your Own Cert

By default MagTape will handle creation and rotation of the required TLS cert/key automatically. In cases where you need to BYOC, you can adjust the configuration.

### Create the secret

Create the secret name called `magtape-tls` with the annotation `magtape-byoc` in the `magtape-system` namespace. The `cert.pem`, `key.pem` must be provided in the data field of the secret. This secret must exist prior to installing MagTape.

```shell
kubectl create secret generic magtape-tls --from-file=cert.pem=<path/to/cert.pem> --from-file=key.pem=<path/to/key.pem> --namespace magtape-system
kubectl annotate secret magtape-tls magtape-byoc=<VALUE>
```
### Root CA

The VWC (Validating Webhook Configuration) needs to be configured with a cert bundle that includes the CA that signed the certificate and key used to secure the MagTape API. For now MagTape assumes this CA certificate exists in the `magtape-tls-ca` secret deployed within the `magtape-system` namespace.  The `rootca.pem` must be provided in the data field of the secret. This secret must exist prior to installing MagTape.

```shell
kubectl create secret generic magtape-tls-ca --from-file=rootca.pem=</path/to/rootca.pem> --namespace magtape-system
```
No validation is done currently to ensure the specified CA actually signed the cert and key used to secure MagTape's API. We plan to add this validation in a future release.

## VWC Template

MagTape makes use of the Kubernetes VWC (Validating Webhook Configuration) feature. This means it requires a `ValidatingWebhookConfiguration` resource to be deployed. The MagTape init process takes care of creating the VWC resource for you. MagTape uses a template defined within a configmap resource for the VWC creation.  

You can adjust the VWC configuration in [this file](/deploy/manifests/magtape-vwc.yaml) and use it to create a new template.

```shell
$ kubectl create cm magtape-vwc-template -n magtape-system --from-file=magtape-vwc=deploy/manifests/magtape-vwc.yaml
```
