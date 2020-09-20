package kubernetes.admission.test_port_name_mismatch

import data.kubernetes.admission.policy_port_name_mismatch

test_port_name_mismatch_allowed {
	in := {
		"apiVersion": "admission.k8s.io/v1beta1",
		"kind": "AdmissionReview",
		"request": {
			"dryRun": false,
			"kind": {
				"group": "",
				"kind": "Service",
				"version": "v1",
			},
			"namespace": "default",
			"object": {
				"apiVersion": "v1",
				"kind": "Service",
				"metadata": {
					"annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"creationTimestamp\":null,\"labels\":{\"app\":\"test-svc\"},\"name\":\"test-svc\",\"namespace\":\"default\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":443,\"protocol\":\"TCP\",\"targetPort\":443}],\"selector\":{\"app\":\"test-svc\"},\"type\":\"ClusterIP\"},\"status\":{\"loadBalancer\":{}}}\n"},
					"creationTimestamp": "2020-02-04T01:16:07Z",
					"labels": {"app": "test-svc"},
					"name": "test-svc",
					"namespace": "default",
					"uid": "ebaa71f7-46eb-11ea-85fd-005056a7b324",
				},
				"spec": {
					"clusterIP": "198.19.241.208",
					"ports": [{
						"name": "https",
						"port": 443,
						"protocol": "TCP",
						"targetPort": 443,
					}],
					"selector": {"app": "test-svc"},
					"sessionAffinity": "None",
					"type": "ClusterIP",
				},
				"status": {"loadBalancer": {}},
			},
			"oldObject": null,
			"operation": "CREATE",
			"resource": {
				"group": "",
				"resource": "services",
				"version": "v1",
			},
			"uid": "ebaa77b8-46eb-11ea-85fd-005056a7b324",
			"userInfo": {
				"groups": [
					"group1",
					"group2",
				],
				"username": "user2",
			},
		},
	}

	count(policy_port_name_mismatch.deny) == 0 with input as in
}

test_port_name_mismatch_denied {
	in := {
		"apiVersion": "admission.k8s.io/v1beta1",
		"kind": "AdmissionReview",
		"request": {
			"dryRun": false,
			"kind": {
				"group": "",
				"kind": "Service",
				"version": "v1",
			},
			"namespace": "default",
			"object": {
				"apiVersion": "v1",
				"kind": "Service",
				"metadata": {
					"annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"creationTimestamp\":null,\"labels\":{\"app\":\"test-svc\"},\"name\":\"test-svc\",\"namespace\":\"default\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":443,\"protocol\":\"TCP\",\"targetPort\":443}],\"selector\":{\"app\":\"test-svc\"},\"type\":\"ClusterIP\"},\"status\":{\"loadBalancer\":{}}}\n"},
					"creationTimestamp": "2020-02-04T01:16:07Z",
					"labels": {"app": "test-svc"},
					"name": "test-svc",
					"namespace": "default",
					"uid": "ebaa71f7-46eb-11ea-85fd-005056a7b324",
				},
				"spec": {
					"clusterIP": "198.19.241.208",
					"ports": [{
						"name": "http",
						"port": 443,
						"protocol": "TCP",
						"targetPort": 443,
					}],
					"selector": {"app": "test-svc"},
					"sessionAffinity": "None",
					"type": "ClusterIP",
				},
				"status": {"loadBalancer": {}},
			},
			"oldObject": null,
			"operation": "CREATE",
			"resource": {
				"group": "",
				"resource": "services",
				"version": "v1",
			},
			"uid": "ebaa77b8-46eb-11ea-85fd-005056a7b324",
			"userInfo": {
				"groups": [
					"group1",
					"group2",
				],
				"username": "user2",
			},
		},
	}

	# count(policy_port_name_mismatch.deny) == 1 with input as in
	policy_port_name_mismatch.deny[_] == {
		"errcode": "MT1006",
		"msg": "[FAIL] HIGH - Logical port name \"http\" mismatch with port number \"443\" for service \"test-svc\" (MT1006)",
		"name": "policy-port-name-mismatch",
		"severity": "HIGH",
	} with input as in
}
