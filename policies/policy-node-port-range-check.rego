package kubernetes.admission.policy_nodeport_range

import data.kubernetes.namespaces

policy_metadata = {
	# Set MagTape Policy Info
	"name": "policy-nodeport-range",
	"severity": "MED",
	"errcode": "MT2002",
	"targets": {"Service"},
}

kind = input.request.kind.kind

svc_type = input.request.object.spec.type

exception_val = "na"

matches {
	# Verify request object type matches targets
	# Verify service is of type NodePort
	policy_metadata.targets[kind]
	svc_type == "NodePort"
}

# Generate violation if nodePort Range is not within allocated range
deny[info] {
	# ns_name: namespace connected to service trying to be deployed
	# ports: where the hostport config is found within the service
	# np_range: pull the information connected to the nodeportRange label in the namespace yaml config
	ns_name := input.request.namespace
	service_name := input.request.object.metadata.name
	ports := input.request.object.spec.ports

	port := ports[_]
	np := port.nodePort
	np_range := data.kubernetes.namespaces[ns_name].metadata.annotations["k8s.t-mobile.com/nodeportRange"]
	port_in_range := check_nodeport_range(np, np_range)

	# Build message to return
	msg := sprintf("[FAIL] %v - nodePort %v %v for Service \"%v\" (%v)", [policy_metadata.severity, np, port_in_range, service_name, policy_metadata.errcode])

	info := {
		"name": policy_metadata.name,
		"severity": policy_metadata.severity,
		"errcode": policy_metadata.errcode,
		"msg": msg,
	}
}

# Generate violation if annotation contains anything besides #, commas, hyphen, or exception_val
deny[info] {
	# ns_name: namespace connected to service trying to be deployed
	# ports: where the hostport config is found within the service
	# np_range: pull the information connected to the nodeportRange label in the namespace yaml config
	ns_name := input.request.namespace
	service_name := input.request.object.metadata.name
	ports := input.request.object.spec.ports

	port := ports[_]
	np_range := data.kubernetes.namespaces[ns_name].metadata.annotations["k8s.t-mobile.com/nodeportRange"]
	annotation_valid := check_annotation(np_range, exception_val)

	# Build message to return
	msg := sprintf("[FAIL] %v - Invalid data in nodePort annotation in \"%v\" namespace (%v)", [policy_metadata.severity, ns_name, policy_metadata.errcode])
	info := {
		"name": policy_metadata.name,
		"severity": policy_metadata.severity,
		"errcode": policy_metadata.errcode,
		"msg": msg,
	}
}

# Check_annotation accepts two values (np, np_range)
# Returns whether the nodeport range contains unknown symbols and is not the exception value
check_annotation(np_range, exception_val) {
	not re_match(`^[-, ]*[0-9 ]+(?:-[0-9 ]+)?(,[0-9 ]+(?:-[0-9 ]+)?)*[-, ]*$`, trim_space(np_range))
	lower(trim_space(np_range)) != exception_val
}

# Check_nodeport_range accepts two values (np, np_range) 
# Returns whether the nodeport(np) is within the range(np_range)
check_nodeport_range(np, np_range) = "is out of defined range" {
	contains(np_range, "-")
	contains(np_range, ",")
	re_match(`^[-, ]*[0-9 ]+(?:-[0-9 ]+)?(,[0-9 ]+(?:-[0-9 ]+)?)*[-, ]*$`, trim_space(np_range))
	range_split := split(np_range, ",")
	not range_matches_any(np, range_split)
} else = "is out of defined range" {
	contains(np_range, "-")
	not contains(np_range, ",")
	re_match(`^[-, ]*[0-9 ]+(?:-[0-9 ]+)?(,[0-9 ]+(?:-[0-9 ]+)?)*[-, ]*$`, trim_space(np_range))
	not range_matches(np, np_range)
} else = "is out of defined range" {
	contains(np_range, ",")
	not contains(np_range, "-")
	re_match(`^[-, ]*[0-9 ]+(?:-[0-9 ]+)?(,[0-9 ]+(?:-[0-9 ]+)?)*[-, ]*$`, trim_space(np_range))
	range_split := split(np_range, ",")
	not range_matches_any(np, range_split)
} else = "is out of defined range" {
	not contains(np_range, ",")
	not contains(np_range, "-")
	re_match(`^\d+$`, trim_space(np_range))
	to_number(trim_space(np_range)) != to_number(np)
}

range_matches_any(npNum, list) {
	range_matches(npNum, list[_])
}

# Checks if nodePort is in comma separated list
range_matches(npNum, list) {
	not contains(list, "-")
	not contains(list, ",")
	count(trim_space(list)) > 0

	to_number(trim_space(list)) == to_number(npNum)
}

# Checks if nodePort is within range
range_matches(npNum, list) {
	contains(list, "-")
	range_split := split(list, "-")
	count(trim_space(range_split[0])) > 0
	count(trim_space(range_split[1])) > 0

	to_number(npNum) >= to_number(trim_space(range_split[0]))
	to_number(npNum) <= to_number(trim_space(range_split[1]))
}
