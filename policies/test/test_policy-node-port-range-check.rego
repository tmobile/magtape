package kubernetes.admission.policy_nodeport_range

test_np_single_allowed {
	ns = data.mock.test_np_namespace_single_30100
	result = deny with input as data.mock.test_np_single_30100 with data.kubernetes.namespaces.test1 as ns
	count(result) == 0
}

test_np_range_comma_allowed {
	ns = data.mock.test_np_namespace_range_comma
	result = deny with input as data.mock.test_np_single_30100 with data.kubernetes.namespaces.test1 as ns
	count(result) == 0
}

test_np_range_dash_allowed {
	ns = data.mock.test_np_namespace_range_dash
	result = deny with input as data.mock.test_np_single_30150 with data.kubernetes.namespaces.test1 as ns
	count(result) == 0
}

test_np_range_mixed_allowed {
	ns = data.mock.test_np_namespace_range_dash_and_comma
	result = deny with input as data.mock.test_np_single_30187 with data.kubernetes.namespaces.test1 as ns
	count(result) == 0
}

test_np_range_exempt_allowed {
	ns = data.mock.test_np_namespace_exempt
	result = deny with input as data.mock.test_np_single_30187 with data.kubernetes.namespaces.test1 as ns
	count(result) == 0
}

test_np_single_denied {
	ns = data.mock.test_np_namespace_single_30100
	result = deny[_] with input as data.mock.test_np_single_30101 with data.kubernetes.namespaces.test1 as ns
	result == {
		"errcode": "MT2002",
		"msg": "[FAIL] MED - nodePort 30101 is out of defined range for Service \"test-svc\" (MT2002)",
		"name": "policy-nodeport-range",
		"severity": "MED",
	}
}

test_np_range_comma_denied {
	ns = data.mock.test_np_namespace_range_comma
	result = deny[_] with input as data.mock.test_np_single_30101 with data.kubernetes.namespaces.test1 as ns
	result == {
		"errcode": "MT2002",
		"msg": "[FAIL] MED - nodePort 30101 is out of defined range for Service \"test-svc\" (MT2002)",
		"name": "policy-nodeport-range",
		"severity": "MED",
	}
}

test_np_range_dash_denied {
	ns = data.mock.test_np_namespace_range_dash
	result = deny[_] with input as data.mock.test_np_single_30075 with data.kubernetes.namespaces.test1 as ns
	result == {
		"errcode": "MT2002",
		"msg": "[FAIL] MED - nodePort 30075 is out of defined range for Service \"test-svc\" (MT2002)",
		"name": "policy-nodeport-range",
		"severity": "MED",
	}
}

test_np_range_mixed_denied {
	ns = data.mock.test_np_namespace_range_dash_and_comma
	result = deny[_] with input as data.mock.test_np_single_30075 with data.kubernetes.namespaces.test1 as ns
	result == {
		"errcode": "MT2002",
		"msg": "[FAIL] MED - nodePort 30075 is out of defined range for Service \"test-svc\" (MT2002)",
		"name": "policy-nodeport-range",
		"severity": "MED",
	}
}

test_np_range_extra_dash_denied {
	ns = data.mock.test_np_namespace_range_extra_dash
	result = deny[_] with input as data.mock.test_np_single_30075 with data.kubernetes.namespaces.test1 as ns
	result == {
		"errcode": "MT2002",
		"msg": "[FAIL] MED - nodePort 30075 is out of defined range for Service \"test-svc\" (MT2002)",
		"name": "policy-nodeport-range",
		"severity": "MED",
	}
}

test_np_range_alpha_chars_denied {
	ns = data.mock.test_np_namespace_range_alpha_chars
	result = deny[_] with input as data.mock.test_np_single_30187 with data.kubernetes.namespaces.test1 as ns
	result == {
		"errcode": "MT2002",
		"msg": "[FAIL] MED - Invalid data in nodePort annotation in \"test1\" namespace (MT2002)",
		"name": "policy-nodeport-range",
		"severity": "MED",
	}
}

test_np_range_special_chars_denied {
	ns = data.mock.test_np_namespace_range_special_chars
	result = deny[_] with input as data.mock.test_np_single_30187 with data.kubernetes.namespaces.test1 as ns
	result == {
		"errcode": "MT2002",
		"msg": "[FAIL] MED - Invalid data in nodePort annotation in \"test1\" namespace (MT2002)",
		"name": "policy-nodeport-range",
		"severity": "MED",
	}
}

test_np_range_empty_denied {
	ns = data.mock.test_np_namespace_empty
	result = deny[_] with input as data.mock.test_np_single_30187 with data.kubernetes.namespaces.test1 as ns
	result == {
		"errcode": "MT2002",
		"msg": "[FAIL] MED - Invalid data in nodePort annotation in \"test1\" namespace (MT2002)",
		"name": "policy-nodeport-range",
		"severity": "MED",
	}
}
