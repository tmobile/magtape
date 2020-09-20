package kubernetes.admission.policy_liveness_probe

test_liveness_probe_allowed {

	result = deny with input as data.mock.liveness_probe_allowed
	count(result) == 0 

}

test_liveness_probe_denied {

	result = deny with input as data.mock.liveness_probe_denied
	count(result) == 1

}

test_unmatched_resource {

	result = deny with input as data.mock.unmatched_resource
	count(result) == 0

}