package kubernetes.admission.policy_host_path

test_host_path_allowed {
	
	result = deny with input as data.mock.test_host_path_allowed
	count(result) == 0 

}

test_host_path_denied {

	result = deny[_] with input as data.mock.test_host_path_denied
	result = {
		"errcode": "MT1010",
		"msg": "[FAIL] MED - hostPath is configured for volume \"default-token\" (MT1010)",
		"name": "policy-host-path",
		"severity": "MED",
	}

}
