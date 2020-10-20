package kubernetes.admission.policy_hostport

test_host_port_allowed {
	result = deny with input as data.mock.test_host_port_allowed
	count(result) == 0
}

test_host_port_denied {
	result = deny[_] with input as data.mock.test_host_port_denied
	result == {
		"errcode": "MT1008",
		"msg": "[FAIL] HIGH - hostPort is configured for container \"toolbox\" (MT1008)",
		"name": "policy-hostport",
		"severity": "HIGH",
	}
}
