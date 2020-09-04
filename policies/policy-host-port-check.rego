package kubernetes.admission.policy_hostport

policy_metadata = {

    # Set MagTape Policy Info
    "name": "policy-hostport",
    "severity": "HIGH",
    "errcode": "MT1008",
    "targets": {"Pod"},

}

kind = input.request.kind.kind

matches {

    # Verify request object type matches targets
    policy_metadata.targets[kind]

}

deny[info] {

    # Find container spec
    # Since only target is Pod, containers will always be found in same place
    containers := input.request.object.spec.containers

    # Check for hostPort in each container spec
    container := containers[_]
    name := container.name
    port_present := check_hostport(container)

    # Build message to return
    msg := sprintf("[FAIL] %v - %v for container \"%v\" (%v)", [policy_metadata.severity, port_present, name, policy_metadata.errcode])

    info := {

        "name": policy_metadata.name,
        "severity": policy_metadata.severity,
        "errcode": policy_metadata.errcode,
        "msg": msg,

    }

}

# check_hostport accepts a value (container) 
# returns whether the hostPort is found in config
check_hostport(container) = "hostPort is configured" {

    ports := container.ports[_]
    ports.hostPort

}
