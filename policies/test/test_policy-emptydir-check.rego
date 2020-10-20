package kubernetes.admission.policy_emptydir

test_emptydir_allowed {
	result = deny with input as data.mock.test_emptydir_allowed
	count(result) == 0
}

test_emptydir_large_denied {
	result = deny[_] with input as data.mock.test_emptydir_large_denied
	result == {
		"errcode": "MT1009",
		"msg": "[FAIL] MED - Size limit of emptyDir volume \"default-token\" is greater than 100 Megabytes (MT1009)",
		"name": "policy-emptydir",
		"severity": "MED",
	}
}

test_emptydir_wrong_ending_denied {
	result = deny[_] with input as data.mock.test_emptydir_wrong_ending_denied
	result == {
		"errcode": "MT1009",
		"msg": "[FAIL] MED - Size limit of emptyDir volume \"default-token\" is not in Megabytes (MT1009)",
		"name": "policy-emptydir",
		"severity": "MED",
	}
}

test_emptydir_not_set_denied {
	result = deny[_] with input as data.mock.test_emptydir_not_set_denied
	result == {
		"errcode": "MT1009",
		"msg": "[FAIL] MED - Size limit of emptyDir volume \"default-token\" is not set (MT1009)",
		"name": "policy-emptydir",
		"severity": "MED",
	}
}
