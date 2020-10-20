package kubernetes.admission.policy_singleton_pod_check

test_pod_singleton_allowed {
	result = deny with input as data.mock.test_pod_singleton_allowed
	count(result) == 0
}

test_pod_singleton_denied {
	result = deny[_] with input as data.mock.test_pod_singleton_denied
	result == {
		"errcode": "MT1007",
		"msg": "[FAIL] LOW - \"toolbox\" is a singleton pod. (MT1007)",
		"name": "policy-singleton-pod-check",
		"severity": "LOW",
	}
}
