# Policies

The following policies are included as examples for what you can enforce/validated with MagTape. Since MagTape uses OPA as the policy engine, it can support pretty much any policy that OPA can. 

## Liveness Probe (Check ID: MT1001)

This policy verifies that your workload configuration includes a liveness probe.

The liveness probe is used to determine if your workload is "alive" or if a given pod should be restarted to resolve the workload to a known good state. This enabled some of the self healing properties of the Kubernetes platform.

Refer to the [official Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) for implementation patterns

## Readiness Probe (Check ID: MT1002)

This policy checks your workload for a Readiness probe configuration. 

Sometimes, applications are temporarily unable to serve traffic. For example, an application might need to load large data or configuration files during startup, or depend on external services after startup. In such cases, you don’t want to kill the application, but you don’t want to send it requests either. Kubernetes provides readiness probes to detect and mitigate these situations. A pod with containers reporting that they are not ready does not receive traffic through Kubernetes Services.

Please refer to the [official Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#define-readiness-probes) for specifics on Readiness Probe configuration

## Resource Limits (Check ID: MT1003)

This policy checks for configured resource limits within a workload spec.

Resource limits define the maximum resources (CPU/Memory) that a pod can use. If unspecified the pod will inherit the default limits from the namespace configuration. These defaults are typically very low and can result in resource starvation for a workload. You should evaluate your workload during normal and peak conditions to size the limits appropriately. These values should be reevaluated over time to ensure accuracy. Resource Limits can be used in conjunction with Resource Requests to allow for a range of resources available to pods.

Refer to the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container) for more details on resource limits and configurations

## Resource Requests (Check ID: MT1004)

This policy checks for configured resource requests within a workload spec.

Resource requests define the initial resources (CPU/Memory) assigned to a pod when it starts up. If unspecified the pod will inherit the default requests from the namespace configuration. These defaults are typically very low and can result in resource starvation for a workload. You should evaluate your workload during normal and peak conditions to size the requests appropriately. These values should be reevaluated over time to ensure accuracy. Resource Limits can be used in conjunction with Resource Requests to allow for a range of resources available to pods.

Refer to the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container) for more details on resource requests and configurations

## Pod Disruption Budget (Check ID: MT1005)

This policy checks the configuration of a Pod Disruption Budget object and verifies it follows recommended logic.

The Pod Disruption Budget allows you to specify a configuration to limit the number of concurrent disruptions that your application experiences, allowing for higher availability while permitting the cluster administrator to manage platform level updates to underlying cluster components. This is done by specifying either "minAvailable" or "maxUnavailable".

The configuration should follow these recommended rules:

Always use a percentage value for "minAvailable" or "maxUnavailable", never an integer value
The values should always allow for a failure of one third (a complete Availability Zone loss)
minAvailable value should be less than or equal to 66%
maxUnavailable value should be greater than or equal to 33%
The values for "minAvailable" or "maxUnavailable" should take your workload replica count into consideration (This should prevent PDB configurations from blocking platform level maintenance operations)
replicacount - (PDB% * replicacount) >= 1

You can find more information about Pod Disruption Budgets within the [official Kubernetes documentation](https://kubernetes.io/docs/tasks/run-application/configure-pdb)

## Istio Port Name/Number Mismatch (Check ID: MT1006)

This policy checks the configuration of a Service object and verifies it does not include a name/port mismatch.

Kubernetes Service resources allow you to configure a logical name to associate with a specific port defined within the spec. The Istio Service Mesh uses the logical names of ports in Service resources to identify protocols. If a Service resource has a logical port name of "http" and a port number of "443" it gets confused (it expects the name "https" to be matched to port "443"). When this happens any pod that uses an Istio deployed Envoy sidecar proxy will begin to have connectivity issues as the Envoy config becomes invalid.

Ideally you should match protocol to port number similar to:

https → 443
http → 80

Or, and even safer option is to be generic:

web → 80 or 443

The upstream Istio project is working to resolve this [issue](https://github.com/istio/istio/issues/16458).

### Example Bag Policy

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: test-svc
  name: test-svc
spec:
  ports:
  - name: http
    port: 443
    protocol: TCP
    targetPort: 443
  selector:
    app: test-svc
  type: ClusterIP
```

## Privileged Pod Security Context (Check ID: MT2001)

This policy checks for the existence of a Privileged Pod Security Context within the workload configuration and will deny the workload if detected.

Pods can enable privileged mode, using the privileged flag on the SecurityContext of the container spec. This configuration allows for many unintended security related vulnerabilities and should therefore be disallowed on clusters. This is a pretty basic check, and there are certainly more ways to abuse a pods security context, but this should provide a base to start from to build a more advanced policy.

Read more about Privileged Pods in the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/pods/pod/#privileged-mode-for-pod-containers)
