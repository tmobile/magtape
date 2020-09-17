package kubernetes.admission.test_policy_liveness_probe

import data.kubernetes.admission.policy_liveness_probe

test_liveness_probe_allowed {
    in := {
        "apiVersion": "admission.k8s.io/v1beta1",
            "kind": "AdmissionReview",
            "request": {
            "dryRun": false,
            "kind": {
                "group": "apps",
                "kind": "Deployment",
                "version": "v1"
            },
            "namespace": "test1",
            "object": {
                "apiVersion": "apps/v1",
                "kind": "Deployment",
                "metadata": {
                "annotations": {
                    "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"metadata\":{\"annotations\":{},\"labels\":{\"app\":\"test-deploy01\"},\"name\":\"test-deploy01\",\"namespace\":\"test1\"},\"spec\":{\"replicas\":1,\"selector\":{\"matchLabels\":{\"app\":\"test-deploy01\"}},\"template\":{\"metadata\":{\"labels\":{\"app\":\"test-deploy01\"}},\"spec\":{\"containers\":[{\"args\":[\"/server\"],\"image\":\"k8s.gcr.io/liveness\",\"livenessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"name\":\"test-deploy01\",\"readinessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"resources\":{\"limits\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"},\"requests\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"}}}]}}}}\n"
                },
                "creationTimestamp": "2019-08-05T04:58:34Z",
                "generation": 1,
                "labels": {
                    "app": "test-deploy01"
                },
                "name": "test-deploy01",
                "namespace": "test1",
                "uid": "51ab8ca1-93c9-4c71-88d6-479610b0597a"
                },
                "spec": {
                    "template": {
                        "metadata": {
                            "creationTimestamp": null,
                            "labels": {
                                "app": "test-deploy01"
                            }
                        },
                        "spec": {
                            "containers": [
                                {
                                "name": "test-deploy01",
                                "livenessProbe": {
                                    "failureThreshold": 3,
                                    "httpGet": {
                                    "httpHeaders": [
                                        {
                                        "name": "X-Custom-Header",
                                        "value": "Awesome"
                                        }
                                    ],
                                    "path": "/healthz",
                                    "port": 8080,
                                    "scheme": "HTTP"
                                    },
                                    "initialDelaySeconds": 3,
                                    "periodSeconds": 3,
                                    "successThreshold": 1,
                                    "timeoutSeconds": 1
                                },
                                "resources": {
                                    "limits": {
                                    "cpu": "50m",
                                    "memory": "128Mi"
                                    },
                                    "requests": {
                                    "cpu": "50m",
                                    "memory": "128Mi"
                                    }
                                },
                                "terminationMessagePath": "/dev/termination-log",
                                "terminationMessagePolicy": "File"
                                }
                            ]
                        }
                    }
                },
                "status": {}
            }
        }
    }

    count(policy_liveness_probe.deny) == 0 with input as in
}

test_readiness_probe_denied {
    in := { "apiVersion": "admission.k8s.io/v1beta1",
        "kind": "AdmissionReview",
        "request": {
            "dryRun": false,
            "kind": {
                "group": "apps",
                "kind": "Deployment",
                "version": "v1"
            },
            "namespace": "test1",
            "object": {
                "apiVersion": "apps/v1",
                "kind": "Deployment",
                "metadata": {
                "annotations": {
                    "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"metadata\":{\"annotations\":{},\"labels\":{\"app\":\"test-deploy01\"},\"name\":\"test-deploy01\",\"namespace\":\"test1\"},\"spec\":{\"replicas\":1,\"selector\":{\"matchLabels\":{\"app\":\"test-deploy01\"}},\"template\":{\"metadata\":{\"labels\":{\"app\":\"test-deploy01\"}},\"spec\":{\"containers\":[{\"args\":[\"/server\"],\"image\":\"k8s.gcr.io/liveness\",\"livenessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"name\":\"test-deploy01\",\"readinessProbe\":{\"httpGet\":{\"httpHeaders\":[{\"name\":\"X-Custom-Header\",\"value\":\"Awesome\"}],\"path\":\"/healthz\",\"port\":8080},\"initialDelaySeconds\":3,\"periodSeconds\":3},\"resources\":{\"limits\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"},\"requests\":{\"cpu\":\"50m\",\"memory\":\"128Mi\"}}}]}}}}\n"
                },
                "creationTimestamp": "2019-08-05T04:58:34Z",
                "generation": 1,
                "labels": {
                    "app": "test-deploy01"
                },
                "name": "test-deploy01",
                "namespace": "test1",
                "uid": "51ab8ca1-93c9-4c71-88d6-479610b0597a"
                },
                "spec": {
                    "template": {
                        "metadata": {
                            "creationTimestamp": null,
                            "labels": {
                                "app": "test-deploy01"
                            }
                        },
                        "spec": {
                            "containers": [
                                {
                                "name": "test-deploy01",
                                "resources": {
                                    "limits": {
                                    "cpu": "50m",
                                    "memory": "128Mi"
                                    },
                                    "requests": {
                                    "cpu": "50m",
                                    "memory": "128Mi"
                                    }
                                },
                                "terminationMessagePath": "/dev/termination-log",
                                "terminationMessagePolicy": "File"
                                }
                            ]
                        }
                    }
                },
                "status": {}
            }
        }
    }


    # count(policy_host_path.deny) == 1 with input as in
    policy_liveness_probe.deny[_] ==    {
            "errcode": "MT1001",
            "msg": "[FAIL] LOW - Liveness Probe missing for container \"test-deploy01\" (MT1001)",
            "name": "policy-liveness-probe",
            "severity": "LOW"
        }
    with input as in
}
