package kubernetes.admission.policy_privileged_pod

test_privileged_pod_allowed {
	
	result = deny with input as data.mock.test_privileged_pod_allowed
	count(result) == 0 
	
}

test_privileged_pod_denied {
	
	result = deny[_] with input as data.mock.test_privileged_pod_denied
	result == {
		"errcode": "MT2001",
		"msg": "[FAIL] HIGH - Found privileged Security Context for container \"test-deploy01\" (MT2001)",
		"name": "policy-privileged-pod",
		"severity": "HIGH",
	}

}
