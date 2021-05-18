# Policies

The following policies are included as examples of what you can enforce/validate with MagTape. Since MagTape uses OPA as the policy engine, it can support pretty much any policy that OPA can with just a few modifications. Detail on what is required for a policy to work for MagTape and how you can deploy a policy to a cluster is described [here](/README.md#policies)

## Liveness Probe (Check ID: MT1001)

This policy verifies that your workload configuration includes a liveness probe.

The liveness probe is used to determine if your workload is "alive" or if a given pod should be restarted to resolve the workload to a known good state. This enabled some of the self-healing properties of the Kubernetes platform.

Refer to the [official Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) for implementation patterns

## Readiness Probe (Check ID: MT1002)

This policy checks your workload for a Readiness probe configuration.

Sometimes, applications are temporarily unable to serve traffic. For example, an application might need to load large data or configuration files during startup or depend on external services after startup. In such cases, you don’t want to kill the application, but you don’t want to send it requests either. Kubernetes provides readiness probes to detect and mitigate these situations. A pod with containers reporting that they are not ready does not receive traffic through Kubernetes Services.

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

The Pod Disruption Budget allows you to specify a configuration to limit the number of concurrent disruptions that your application experiences, allowing for higher availability while permitting the cluster administrator to manage platform-level updates to underlying cluster components. This is done by specifying either "minAvailable" or "maxUnavailable".

The configuration should follow these recommended rules:

- Always use a percentage value for "minAvailable" or "maxUnavailable", never an integer value
- The values should always allow for a failure of one third (a complete Availability Zone loss)
- minAvailable value should be less than or equal to 66%
- maxUnavailable value should be greater than or equal to 33%
- The values for "minAvailable" or "maxUnavailable" should take your workload replica count into consideration (This should prevent PDB configurations from blocking platform level maintenance operations)
- replicacount - (PDB% * replicacount) >= 1

You can find more information about Pod Disruption Budgets within the [official Kubernetes documentation](https://kubernetes.io/docs/tasks/run-application/configure-pdb)

## Istio Port Name/Number Mismatch (Check ID: MT1006)

This policy checks the configuration of a Service object and verifies it does not include a name/port mismatch.

Kubernetes Service resources allow you to configure a logical name to associate with a specific port defined within the spec. The Istio Service Mesh uses the logical names of ports in Service resources to identify protocols. If a Service resource has a logical port name of "http" and a port number of "443" it gets confused (it expects the name "https" to be matched to port "443"). When this happens any pod that uses an Istio deployed Envoy sidecar proxy will begin to have connectivity issues as the Envoy config becomes invalid.

Ideally, you should match protocol to a port number similar to:

https → 443
http → 80

Or, an even safer option is to be generic:

web → 80 or 443

The upstream Istio project is working to resolve this [issue](https://github.com/istio/istio/issues/16458).

### Example Bad Policy

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

## Singleton Pods (Check ID: MT1007)

This policy checks for singleton Pods by looking for ownerRefrences in the workload configuration.

A singleton pod is one that has no replication control. Without replication control, there may be moments when the pod becomes unavailable and there is no lifecycle management to recreate the pod if it ever dies. If owner references is present in the configuration, the pod is seen as a dependent of a ReplicationController, ReplicaSet, StatefulSet, DaemonSet, Deployment, Job, or CronJob.

Read more about Pods in the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/garbage-collection/#owners-and-dependents)

## Host Port (Check ID: MT1008)

This policy checks for the existence of a hostPort within the workload configuration and will deny the workload if detected.

Pods can be configured with a hostPort in their container spec. This configuration will expose the port to the external network and can lead to port conflicts as the number of applications on the cluster grows.

Read more about host ports in the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/overview/#services)

## emptyDir Volume (Check ID: MT1009)

This policy checks that the size limit for the emptyDir volume is both present and less than the desired size limit.

An emptyDir volume is automatically created when a Pod is assigned to a Node. When the Pod is removed, so is its emptyDir volume. Using emptyDir leads to consumption of ephemeral storage on the underlying nodes and can fill up easily affecting others on the platform.

The configuration should follow these recommended rules:

Always set the emptyDir "sizeLimit"
Define the "sizeLimit" in Megabytes(M)
sizeLimit value should be set to less than 100M

Read more about emptyDir volumes in the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)

## Host Path (Check ID: MT1010)

This policy checks for the existence of a hostPath within the workload configuration.

A hostPath configuration mounts a file or directory from the host node's filesystem to a Pod. If a pod gets rescheduled to a different node, it can act differently due to files being different on each node. Allowing a host path to be set could result in unintended security risks.

Read more about hostPath in the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath)

## Privileged Pod Security Context (Check ID: MT2001)

This policy checks for the existence of a Privileged Pod Security Context within the workload configuration and will deny the workload if detected.

Pods can enable privileged mode, using the privileged flag on the SecurityContext of the container spec. This configuration allows for many unintended security-related vulnerabilities and should therefore be disallowed on clusters. This is a pretty basic check, and there are certainly more ways to abuse a pods security context, but this should provide a base to start from to build a more advanced policy.

Read more about Privileged Pods in the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/pods/pod/#privileged-mode-for-pod-containers)

## Node Port Range (Check ID: MT2002)

This policy enforces that a nodePort configured in a Service falls within the nodePort range that is defined in the corresponding namespace annotation.

NodePorts are used as a way to expose a Service external to a cluster. Since NodePorts are a finite resource, this policy aims to control NodePort usage via an allow list model using annotation on a Namespace to designate the allowable NodePort values/range.

The configuration should follow these recommended rules:

The nodePort range annotation can be a single number, numbers separated by commas, a range split with a hyphen, or a combination of the three
The nodePort annotation on the namespace should be "k8s.t-mobile.com/nodeportRange"
Set the annotation to "na" if no nodePort range will to be set, that is seen as an exceptional value

Read more about NodePorts in the [official Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)
