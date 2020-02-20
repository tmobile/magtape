package kubernetes.admission.policy_resource_requests

policy_metadata = {

    # Set MagTape Policy Info
    "name": "policy-resource-requests",
    "severity": "LOW",
    "errcode": "MT1004",
    "targets": {"Deployment", "StatefulSet", "DaemonSet", "Pod"},

}

servicetype = input.request.kind.kind

matches {

    # Verify request object type matches targets
    policy_metadata.targets[servicetype]
    
}

deny[info] {

    # Find container spec
    containers := find_containers(servicetype, policy_metadata)

    # Check for livenessProbe in each container spec
    container := containers[_]
    name := container.name
    resource_type := get_resource_type(container)

    # Build message to return
    msg := sprintf("[FAIL] %v - Resource requests missing (%v) for container \"%v\" (%v)", [policy_metadata.severity, resource_type, name, policy_metadata.errcode])

    info := {

        "name": policy_metadata.name,
        "severity": policy_metadata.severity,
        "errcode": policy_metadata.errcode,
        "msg": msg,

    }
    
}

# find_containers accepts a value (k8s object type) and returns the container spec
find_containers(type, metadata) = input.request.object.spec.containers {

    type == "Pod"

} else = input.request.object.spec.template.spec.containers {

	metadata.targets[type]
    
}

# get_resource_type accepts a value (containers) and returns the missing resource type based on missing limits
get_resource_type(container) = "CPU/MEM" {

    not container.resources.requests.cpu
    not container.resources.requests.memory
    
} else = "CPU" {
	
    not container.resources.requests.cpu
    
} else = "MEM" {
	
    not container.resources.requests.memory
    
}