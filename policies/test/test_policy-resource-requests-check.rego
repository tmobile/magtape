package kubernetes.admission.policy_resource_requests

test_resource_requests_allowed {
	result = deny with input as data.mock.test_resource_requests_allowed
	count(result) == 0
}

test_requests_denied_cpu {
	result = deny[_] with input as data.mock.test_requests_denied_cpu
	result == {
		"errcode": "MT1004",
		"msg": "[FAIL] LOW - Resource requests missing (CPU) for container \"test-deploy01\" (MT1004)",
		"name": "policy-resource-requests",
		"severity": "LOW",
	}
}

test_requests_denied_mem {
	result = deny[_] with input as data.mock.test_requests_denied_mem
	result == {
		"errcode": "MT1004",
		"msg": "[FAIL] LOW - Resource requests missing (MEM) for container \"test-deploy01\" (MT1004)",
		"name": "policy-resource-requests",
		"severity": "LOW",
	}
}

test_requests_denied_mem_cpu {
	result = deny[_] with input as data.mock.test_requests_denied_mem_cpu
	result == {
		"errcode": "MT1004",
		"msg": "[FAIL] LOW - Resource requests missing (CPU/MEM) for container \"test-deploy01\" (MT1004)",
		"name": "policy-resource-requests",
		"severity": "LOW",
	}
}
