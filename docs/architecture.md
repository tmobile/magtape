# MagTape Architecture

![magtape-architecture](/images/magtape-workflow.png)

MagTape is a workload that contains a single init container and 3 runtime containers.

## Init Containers

- magtape-init

The MagTape init container takes care of generating the required cert/key pair for TLS and also manages the creation and patching of the Validating Webhook Configuration. The init container will handle rotation of the cert/key as needed if you utilize the default functionality, which leverages the Kubernetes certificates API.

## Runtime Containers

- magtape
- opa
- kube-mgmt

The MagTape app itself is a Python Flask application that hosts the required endpoints to receive Admission Requests from the Kubernetes API server. When it receives a request is makes a call to OPA (used as a sidecar in this case) to evaluate the request against the defined policies and produce a response. The response is specifically formatted to allow MagTape to assess additional logic and determine if:

- If the request should be allowed or denied
- If an alert should send
- If a Kubernetes event should be created
- If, and which, metrics should be incremented
- Etc.

The kube-mgmt container is setup to build a cache of kubernetes resources (as configured) and replicate them to OPA to allow for policies that include context outside of the request object itself.
