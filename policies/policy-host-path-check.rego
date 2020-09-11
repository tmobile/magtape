package kubernetes.admission.policy_host_path

policy_metadata = {

    # Set MagTape Policy Info
    "name": "policy-host-path",
    "severity": "MED",
    "errcode": "MT1010",
    "targets": {"Pod"},

}

kind = input.request.kind.kind

matches {

    # Verify request object type matches targets
    policy_metadata.targets[kind]
    
}

deny[info] {

    # Find volume spec
    volumes := input.request.object.spec.volumes

    # Check for hostPath in each volume spec
    volume := volumes[_]
    name := volume.name
	hostpath_state := check_hostpath(volume)

    # Build message to return
    msg := sprintf("[FAIL] %v - %v for volume \"%v\" (%v)", [policy_metadata.severity, hostpath_state, name, policy_metadata.errcode])

    info := {
		
        "name": policy_metadata.name,
        "severity": policy_metadata.severity,
        "errcode": policy_metadata.errcode,
        "msg": msg,

    }
    
}

# check_hostpath accepts a value (volume)
# returns whether there is a hostPath configured in the volume
check_hostpath(volume) = "hostPath is configured" {
	
	volume.hostPath
    
}
