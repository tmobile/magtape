package kubernetes.admission.policy_liveness_probe

test_liveness_probe_allowed {
	result = deny with input as data.mock.liveness_probe_allowed
	count(result) == 0
}

test_liveness_probe_denied {
	result = deny[_] with input as data.mock.liveness_probe_denied
	result == {
		"errcode": "MT1001",
		"msg": "[FAIL] LOW - Liveness Probe missing for container \"test-deploy01\" (MT1001)",
		"name": "policy-liveness-probe",
		"severity": "LOW",
	}
}

test_unmatched_resource {
	result = deny with input as data.mock.unmatched_resource
	count(result) == 0
}
