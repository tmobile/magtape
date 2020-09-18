package kubernetes.admission.policy_port_name_mismatch

policy_metadata = {
	# Set MagTape Policy Info
	"name": "policy-port-name-mismatch",
	"severity": "HIGH",
	"errcode": "MT1006",
	"targets": {"Service"},
}

servicetype = input.request.kind.kind

svc_name := input.request.object.metadata.name

matches {
	# Verify request object type matches targets
	policy_metadata.targets[servicetype]
}

deny[info] {
	# Find service ports
	ports := input.request.object.spec.ports

	# Check all port spec's
	port := ports[_]
	port_name := port.name
	port_number := port.port

	# Check for mismatch between logical port name and port number in service spec
	port_name == "http"
	port_number == 443

	msg = sprintf("[FAIL] %v - Logical port name \"%v\" mismatch with port number \"%v\" for service \"%v\" (%v)", [policy_metadata.severity, port_name, port_number, svc_name, policy_metadata.errcode])

	info := {
		"name": policy_metadata.name,
		"severity": policy_metadata.severity,
		"errcode": policy_metadata.errcode,
		"msg": msg,
	}
}
