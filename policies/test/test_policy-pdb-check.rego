package kubernetes.admission.policy_pdb

test_pdb_allowed_min_high {
	result = deny with input as data.mock.test_pdb_allowed_min_high
	count(result) == 0 
}

test_pdb_allowed_min_low {
	result = deny with input as data.mock.test_pdb_allowed_min_low
	count(result) == 0
}

test_pdb_denied_min_percent {
	result = deny[_] with input as data.mock.test_pdb_denied_min_percent
	result == {
		"errcode": "MT1005",
		"msg": "[FAIL] HIGH - Value (67%) for \"minAvailable\" not within range 0%-66% (MT1005)",
		"name": "policy-pdb",
		"severity": "HIGH",
	}
}

test_pdb_denied_min_int {
	result = deny[_] with input as data.mock.test_pdb_denied_min_int
	result == {
		"errcode": "MT1005",
		"msg": "[FAIL] HIGH - Value \"10\" for \"minAvailable\" should be a Percentage, not an Integer (MT1005)",
		"name": "policy-pdb",
		"severity": "HIGH",
	}
}

test_pdb_denied_max_percent {
	result = deny[_] with input as data.mock.test_pdb_denied_max_percent
	result == {
		"errcode": "MT1005",
		"msg": "[FAIL] HIGH - Value (32%) for \"maxUnavailable\" not within range 33%-100% (MT1005)",
		"name": "policy-pdb",
		"severity": "HIGH",
	}
}

test_pdb_denied_max_int {
	result = deny[_] with input as data.mock.test_pdb_denied_max_int
	result == {
		"errcode": "MT1005",
		"msg": "[FAIL] HIGH - Value \"10\" for \"maxUnavailable\" should be a Percentage, not an Integer (MT1005)",
		"name": "policy-pdb",
		"severity": "HIGH",
	}
}
