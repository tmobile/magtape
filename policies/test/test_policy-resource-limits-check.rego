package kubernetes.admission.policy_resource_limits

test_resource_limits_allowed {
	result = deny with input as data.mock.test_resource_limits_allowed
	count(result) == 0
}

test_limits_denied_cpu {
	result = deny[_] with input as data.mock.test_limits_denied_cpu
	result == {
		"errcode": "MT1003",
		"msg": "[FAIL] LOW - Resource limits missing (CPU) for container \"test-deploy01\" (MT1003)",
		"name": "policy-resource-limits",
		"severity": "LOW",
	}
}

test_limits_denied_mem {
	result = deny[_] with input as data.mock.test_limits_denied_mem
	result == {
		"errcode": "MT1003",
		"msg": "[FAIL] LOW - Resource limits missing (MEM) for container \"test-deploy01\" (MT1003)",
		"name": "policy-resource-limits",
		"severity": "LOW",
	}
}

test_limits_denied_mem_cpu {
	result = deny[_] with input as data.mock.test_limits_denied_mem_cpu
	result == {
		"errcode": "MT1003",
		"msg": "[FAIL] LOW - Resource limits missing (CPU/MEM) for container \"test-deploy01\" (MT1003)",
		"name": "policy-resource-limits",
		"severity": "LOW",
	}
}
