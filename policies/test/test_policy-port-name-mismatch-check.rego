package kubernetes.admission.policy_port_name_mismatch

test_port_name_mismatch_allowed {
	result = deny with input as data.mock.test_port_name_mismatch_allowed
	count(result) == 0 
}

test_port_name_mismatch_denied {
	result = deny[_] with input as data.mock.test_port_name_mismatch_denied
	result == {
		"errcode": "MT1006",
		"msg": "[FAIL] HIGH - Logical port name \"http\" mismatch with port number \"443\" for service \"test-svc\" (MT1006)",
		"name": "policy-port-name-mismatch",
		"severity": "HIGH",
	}
}
