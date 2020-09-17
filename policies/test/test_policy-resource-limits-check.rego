package kubernetes.admission.test_policy_resource_limits

import data.kubernetes.admission.policy_resource_limits

test_resource_limits_allowed {
	in := {{
		"apiVersion": "admission.k8s.io/v1beta1",
		"kind": "AdmissionReview",
		"request": {
			"dryRun": false,
			"kind": {
				"group": "apps",
				"kind": "Deployment",
				"version": "v1",
			},
			"namespace": "test1",
			"object": {
				"apiVersion": "apps/v1",
				"kind": "Deployment",
				"metadata": {
					"annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"metadata\":{\"annotations\":{},\"labels\":{\"app\":\"test-deploy01\"},\"name\":\"test-deploy01\",\"namespace\":\"test1\"},\"spec\":{\"replicas\":1,\"selector\":{\"matchLabels\":{\"app\":\"test-deploy01\"}},\"template\":{\"metadata\":{\"labels\":{\"app\":\"test-deploy01\"}},\"spec\":{\"containers\":[{\"args\":[\"/server\"],\"image\":\"k8s.gcr.io/liveness\",\"livenessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"name\":\"test-deploy01\",\"readinessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"resources\":{\"limits\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"},\"requests\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"}}}]}}}}\n"},
					"creationTimestamp": "2019-08-05T04:58:34Z",
					"generation": 1,
					"labels": {"app": "test-deploy01"},
					"name": "test-deploy01",
					"namespace": "test1",
					"uid": "51ab8ca1-93c9-4c71-88d6-479610b0597a",
				},
				"spec": {
					"progressDeadlineSeconds": 600,
					"replicas": 1,
					"revisionHistoryLimit": 10,
					"selector": {"matchLabels": {"app": "test-deploy01"}},
					"strategy": {
						"rollingUpdate": {
							"maxSurge": "25%",
							"maxUnavailable": "25%",
						},
						"type": "RollingUpdate",
					},
					"template": {
						"metadata": {
							"creationTimestamp": null,
							"labels": {"app": "test-deploy01"},
						},
						"spec": {
							"containers": [{
								"name": "test-deploy01",
								"resources": {
									"limits": {
										"cpu": "50m",
										"memory": "128Mi",
									},
									"requests": {
										"cpu": "50m",
										"memory": "128Mi",
									},
								},
								"terminationMessagePath": "/dev/termination-log",
								"terminationMessagePolicy": "File",
							}],
							"dnsPolicy": "ClusterFirst",
							"restartPolicy": "Always",
							"schedulerName": "default-scheduler",
							"securityContext": {},
							"terminationGracePeriodSeconds": 30,
						},
					},
				},
				"status": {},
			},
		},
	}}

	count(policy_resource_limits.deny) == 0 with input as in
}

test_limits_denied_cpu {
	in := {
		"apiVersion": "admission.k8s.io/v1beta1",
		"kind": "AdmissionReview",
		"request": {
			"dryRun": false,
			"kind": {
				"group": "apps",
				"kind": "Deployment",
				"version": "v1",
			},
			"namespace": "test1",
			"object": {
				"apiVersion": "apps/v1",
				"kind": "Deployment",
				"metadata": {
					"annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"metadata\":{\"annotations\":{},\"labels\":{\"app\":\"test-deploy01\"},\"name\":\"test-deploy01\",\"namespace\":\"test1\"},\"spec\":{\"replicas\":1,\"selector\":{\"matchLabels\":{\"app\":\"test-deploy01\"}},\"template\":{\"metadata\":{\"labels\":{\"app\":\"test-deploy01\"}},\"spec\":{\"containers\":[{\"args\":[\"/server\"],\"image\":\"k8s.gcr.io/liveness\",\"livenessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"name\":\"test-deploy01\",\"readinessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"resources\":{\"limits\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"},\"requests\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"}}}]}}}}\n"},
					"creationTimestamp": "2019-08-05T04:58:34Z",
					"generation": 1,
					"labels": {"app": "test-deploy01"},
					"name": "test-deploy01",
					"namespace": "test1",
					"uid": "51ab8ca1-93c9-4c71-88d6-479610b0597a",
				},
				"spec": {
					"progressDeadlineSeconds": 600,
					"replicas": 1,
					"revisionHistoryLimit": 10,
					"selector": {"matchLabels": {"app": "test-deploy01"}},
					"strategy": {
						"rollingUpdate": {
							"maxSurge": "25%",
							"maxUnavailable": "25%",
						},
						"type": "RollingUpdate",
					},
					"template": {
						"metadata": {
							"creationTimestamp": null,
							"labels": {"app": "test-deploy01"},
						},
						"spec": {
							"containers": [{
								"name": "test-deploy01",
								"resources": {
									"limits": {"memory": "128Mi"},
									"requests": {
										"cpu": "50m",
										"memory": "128Mi",
									},
								},
								"terminationMessagePath": "/dev/termination-log",
								"terminationMessagePolicy": "File",
							}],
							"dnsPolicy": "ClusterFirst",
							"restartPolicy": "Always",
							"schedulerName": "default-scheduler",
							"securityContext": {},
							"terminationGracePeriodSeconds": 30,
						},
					},
				},
				"status": {},
			},
		},
	}

	# count(policy_resource_requests.deny) == 1 with input as in
	policy_resource_limits.deny[_] == {
		"errcode": "MT1003",
		"msg": "[FAIL] LOW - Resource limits missing (CPU) for container \"test-deploy01\" (MT1003)",
		"name": "policy-resource-limits",
		"severity": "LOW",
	} with input as in
}

test_limits_denied_mem {
	in := {
		"apiVersion": "admission.k8s.io/v1beta1",
		"kind": "AdmissionReview",
		"request": {
			"dryRun": false,
			"kind": {
				"group": "apps",
				"kind": "Deployment",
				"version": "v1",
			},
			"namespace": "test1",
			"object": {
				"apiVersion": "apps/v1",
				"kind": "Deployment",
				"metadata": {
					"annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"metadata\":{\"annotations\":{},\"labels\":{\"app\":\"test-deploy01\"},\"name\":\"test-deploy01\",\"namespace\":\"test1\"},\"spec\":{\"replicas\":1,\"selector\":{\"matchLabels\":{\"app\":\"test-deploy01\"}},\"template\":{\"metadata\":{\"labels\":{\"app\":\"test-deploy01\"}},\"spec\":{\"containers\":[{\"args\":[\"/server\"],\"image\":\"k8s.gcr.io/liveness\",\"livenessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"name\":\"test-deploy01\",\"readinessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"resources\":{\"limits\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"},\"requests\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"}}}]}}}}\n"},
					"creationTimestamp": "2019-08-05T04:58:34Z",
					"generation": 1,
					"labels": {"app": "test-deploy01"},
					"name": "test-deploy01",
					"namespace": "test1",
					"uid": "51ab8ca1-93c9-4c71-88d6-479610b0597a",
				},
				"spec": {
					"progressDeadlineSeconds": 600,
					"replicas": 1,
					"revisionHistoryLimit": 10,
					"selector": {"matchLabels": {"app": "test-deploy01"}},
					"strategy": {
						"rollingUpdate": {
							"maxSurge": "25%",
							"maxUnavailable": "25%",
						},
						"type": "RollingUpdate",
					},
					"template": {
						"metadata": {
							"creationTimestamp": null,
							"labels": {"app": "test-deploy01"},
						},
						"spec": {
							"containers": [{
								"name": "test-deploy01",
								"resources": {
									"limits": {"cpu": "50m"},
									"requests": {
										"cpu": "50m",
										"memory": "128Mi",
									},
								},
								"terminationMessagePath": "/dev/termination-log",
								"terminationMessagePolicy": "File",
							}],
							"dnsPolicy": "ClusterFirst",
							"restartPolicy": "Always",
							"schedulerName": "default-scheduler",
							"securityContext": {},
							"terminationGracePeriodSeconds": 30,
						},
					},
				},
				"status": {},
			},
		},
	}

	# count(policy_resource_requests.deny) == 1 with input as in
	policy_resource_limits.deny[_] == {
		"errcode": "MT1003",
		"msg": "[FAIL] LOW - Resource limits missing (MEM) for container \"test-deploy01\" (MT1003)",
		"name": "policy-resource-limits",
		"severity": "LOW",
	} with input as in
}

test_limits_denied_mem_cpu {
	in := {
		"apiVersion": "admission.k8s.io/v1beta1",
		"kind": "AdmissionReview",
		"request": {
			"dryRun": false,
			"kind": {
				"group": "apps",
				"kind": "Deployment",
				"version": "v1",
			},
			"namespace": "test1",
			"object": {
				"apiVersion": "apps/v1",
				"kind": "Deployment",
				"metadata": {
					"annotations": {"kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"metadata\":{\"annotations\":{},\"labels\":{\"app\":\"test-deploy01\"},\"name\":\"test-deploy01\",\"namespace\":\"test1\"},\"spec\":{\"replicas\":1,\"selector\":{\"matchLabels\":{\"app\":\"test-deploy01\"}},\"template\":{\"metadata\":{\"labels\":{\"app\":\"test-deploy01\"}},\"spec\":{\"containers\":[{\"args\":[\"/server\"],\"image\":\"k8s.gcr.io/liveness\",\"livenessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"name\":\"test-deploy01\",\"readinessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"resources\":{\"limits\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"},\"requests\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"}}}]}}}}\n"},
					"creationTimestamp": "2019-08-05T04:58:34Z",
					"generation": 1,
					"labels": {"app": "test-deploy01"},
					"name": "test-deploy01",
					"namespace": "test1",
					"uid": "51ab8ca1-93c9-4c71-88d6-479610b0597a",
				},
				"spec": {
					"progressDeadlineSeconds": 600,
					"replicas": 1,
					"revisionHistoryLimit": 10,
					"selector": {"matchLabels": {"app": "test-deploy01"}},
					"strategy": {
						"rollingUpdate": {
							"maxSurge": "25%",
							"maxUnavailable": "25%",
						},
						"type": "RollingUpdate",
					},
					"template": {
						"metadata": {
							"creationTimestamp": null,
							"labels": {"app": "test-deploy01"},
						},
						"spec": {
							"containers": [{
								"name": "test-deploy01",
								"resources": {
									"limits": {},
									"requests": {
										"cpu": "50m",
										"memory": "128Mi",
									},
								},
								"terminationMessagePath": "/dev/termination-log",
								"terminationMessagePolicy": "File",
							}],
							"dnsPolicy": "ClusterFirst",
							"restartPolicy": "Always",
							"schedulerName": "default-scheduler",
							"securityContext": {},
							"terminationGracePeriodSeconds": 30,
						},
					},
				},
				"status": {},
			},
		},
	}

	# count(policy_resource_requests.deny) == 1 with input as in
	policy_resource_limits.deny[_] == {
		"errcode": "MT1003",
		"msg": "[FAIL] LOW - Resource limits missing (CPU/MEM) for container \"test-deploy01\" (MT1003)",
		"name": "policy-resource-limits",
		"severity": "LOW",
	} with input as in
}
