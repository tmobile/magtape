package kubernetes.admission.policy_singleton_pod_check

policy_metadata = {

    # Set MagTape Policy Info
    "name": "policy-singleton-pod-check",
    "severity": "LOW",
    "errcode": "MT1007",
    "targets": {"Pod"},

}

kind = input.request.kind.kind

matches {

    # Verify request object type matches targets
    policy_metadata.targets[kind]

}

deny[info] {

    name := input.request.object.metadata.name

    # Check for ownerReferences, will only be present if something is dependent on the Pod
    not input.request.object.metadata.ownerReferences

    # Build message to return
    msg := sprintf("[FAIL] %v - \"%v\" is a singleton pod. (%v)", [policy_metadata.severity, name, policy_metadata.errcode])

    info := {

        "name": policy_metadata.name,
        "severity": policy_metadata.severity,
        "errcode": policy_metadata.errcode,
        "msg": msg,

    }
}
