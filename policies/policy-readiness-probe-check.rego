package kubernetes.admission.policy_readiness_probe

policy_metadata = {
	# Set MagTape Policy Info
	"name": "policy-readiness-probe",
	"severity": "LOW",
	"errcode": "MT1002",
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

	# Check for ReadinessProbe in each container spec
	container := containers[_]
	name := container.name
	not container.readinessProbe

	# Build message to return
	msg = sprintf("[FAIL] %v - Readiness Probe missing for container \"%v\" (%v)", [policy_metadata.severity, name, policy_metadata.errcode])

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
}

else = input.request.object.spec.template.spec.containers {
	metadata.targets[type]
}
