package kubernetes.admission.policy_readiness_probe

test_readiness_probe_allowed {
	
	result = deny with input as data.mock.test_readiness_probe_allowed
	count(result) == 0

}

test_readiness_probe_denied {
	
	result = deny[_] with input as data.mock.test_readiness_probe_denied
	result == {
		"errcode": "MT1002",
		"msg": "[FAIL] LOW - Readiness Probe missing for container \"test-deploy01\" (MT1002)",
		"name": "policy-readiness-probe",
		"severity": "LOW",
	}

}
