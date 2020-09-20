package kubernetes.admission.test_policy_singleton_pod_check

import data.kubernetes.admission.policy_singleton_pod_check

test_post_allowed {
	in := {
		"apiVersion": "admission.k8s.io/v1beta1",
		"kind": "AdmissionReview",
		"request": {
			"dryRun": false,
			"kind": {
				"group": "",
				"kind": "Pod",
				"version": "v1",
			},
			"namespace": "test1",
			"object": {
				"apiVersion": "v1",
				"kind": "Pod",
				"metadata": {
					"annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Pod\",\"metadata\":{\"annotations\":{},\"labels\":{\"run\":\"toolbox\"},\"name\":\"toolbox\",\"namespace\":\"test1\",\"ownerReferences\":[{\"apiVersion\":\"v1\",\"kind\":\"Replica\",\"name\":\"my-repset\",\"uid\":\"uidexa1\"}]},\"spec\":{\"containers\":[{\"command\":[\"sleep\",\"360000\"],\"image\":\"jmsearcy/twrtools\",\"imagePullPolicy\":\"Always\",\"livenessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"name\":\"toolbox\",\"readinessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"resources\":{\"limits\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"},\"requests\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"}}}],\"volumes\":[{\"emptyDir\":{\"sizeLimit\":\"50M\"},\"name\":\"default-token\"}]}}\n"},
					"creationTimestamp": "2020-03-04T21:10:51Z",
					"labels": {"run": "toolbox"},
					"name": "toolbox",
					"namespace": "test1",
					"ownerReferences": [{
						"apiVersion": "v1",
						"kind": "Replica",
						"name": "my-repset",
						"uid": "uidexa1",
					}],
					"uid": "a084008f-5e5c-11ea-a33d-005056a72b7b",
				},
			},
		},
	}

	count(policy_singleton_pod_check.deny) == 0 with input as in
}

test_get_anonymous_denied {
	in := {
		"apiVersion": "admission.k8s.io/v1beta1",
		"kind": "AdmissionReview",
		"request": {
			"dryRun": false,
			"kind": {
				"group": "",
				"kind": "Pod",
				"version": "v1",
			},
			"namespace": "test1",
			"object": {
				"apiVersion": "v1",
				"kind": "Pod",
				"metadata": {
					"annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Pod\",\"metadata\":{\"annotations\":{},\"labels\":{\"run\":\"toolbox\"},\"name\":\"toolbox\",\"namespace\":\"test1\",\"ownerReferences\":[{\"apiVersion\":\"v1\",\"kind\":\"Replica\",\"name\":\"my-repset\",\"uid\":\"uidexa1\"}]},\"spec\":{\"containers\":[{\"command\":[\"sleep\",\"360000\"],\"image\":\"jmsearcy/twrtools\",\"imagePullPolicy\":\"Always\",\"livenessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"name\":\"toolbox\",\"readinessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"resources\":{\"limits\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"},\"requests\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"}}}],\"volumes\":[{\"emptyDir\":{\"sizeLimit\":\"50M\"},\"name\":\"default-token\"}]}}\n"},
					"creationTimestamp": "2020-03-04T21:10:51Z",
					"labels": {"run": "toolbox"},
					"name": "toolbox",
					"namespace": "test1",
					"uid": "a084008f-5e5c-11ea-a33d-005056a72b7b",
				},
			},
		},
	}

	# count(policy_singleton_pod_check.deny) == 1 with input as in
	policy_singleton_pod_check.deny[_] == {
		"errcode": "MT1007",
		"msg": "[FAIL] LOW - \"toolbox\" is a singleton pod. (MT1007)",
		"name": "policy-singleton-pod-check",
		"severity": "LOW",
	} with input as in
}
