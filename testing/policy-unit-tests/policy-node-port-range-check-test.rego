package kubernetes.admission.test_policy_nodeport_range

import data.kubernetes.admission.policy_nodeport_range

test_np_range_allowed {
    
    in := {
        "apiVersion": "admission.k8s.io/v1beta1",
        "kind": "AdmissionReview",
        "request": {
            "dryRun": false,
            "kind": {
                "group": "",
                "kind": "Service",
                "version": "v1"
            },
            "namespace": "test1",
            "object": {
                "apiVersion": "v1",
                "kind": "Service",
                "metadata": {
                    "annotations": {
                        "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"creationTimestamp\":null,\"labels\":{\"app\":\"test-svc\"},\"name\":\"test-svc\",\"namespace\":\"test1\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":443,\"protocol\":\"TCP\",\"targetPort\":443}],\"selector\":{\"app\":\"test-svc\"},\"type\":\"ClusterIP\"},\"status\":{\"loadBalancer\":{}}}\n"
                    },
                    "creationTimestamp": "2020-02-04T01:16:07Z",
                    "labels": {
                        "app": "test-svc"
                    },
                    "name": "test-svc",
                    "namespace": "test1",
                    "uid": "ebaa71f7-46eb-11ea-85fd-005056a7b324"
                },
                "spec": {
                    "clusterIP": "198.19.241.208",
                    "ports": [
                        {
                            "name": "http",
                            "nodePort": 30100,
                            "port": 443,
                            "protocol": "TCP",
                            "targetPort": 443
                        }
                    ],
                    "selector": {
                        "app": "test-svc"
                    },
                    "sessionAffinity": "None",
                    "type": "NodePort"
                },
                "status": {
                    "loadBalancer": {}
                }
            }
        }
    }
    ns := {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {
            "annotations": {
                "k8s.t-mobile.com/nodeportRange": " 30100 ",
            },
            "creationTimestamp": "2019-07-11T04:38:16Z",
            "labels": {
                "k8s.t-mobile.com/magtape": "enabled"
            },
            "name": "test1",
            "resourceVersion": "468045109",
            "selfLink": "/api/v1/namespaces/test1",
            "uid": "b394f81c-a395-11e9-a86c-005056a71958"
        },
        "spec": {
            "finalizers": [
                "kubernetes"
            ]
        },
        "status": {
            "phase": "Active"
        }
    }

    count(policy_nodeport_range.deny) == 0
    with input as in
    with data.kubernetes.namespaces["test1"] as ns
}

test_np_range_allowed_one_num {
    
    in := {
        "apiVersion": "admission.k8s.io/v1beta1",
        "kind": "AdmissionReview",
        "request": {
            "dryRun": false,
            "kind": {
                "group": "",
                "kind": "Service",
                "version": "v1"
            },
            "namespace": "test1",
            "object": {
                "apiVersion": "v1",
                "kind": "Service",
                "metadata": {
                    "annotations": {
                        "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"creationTimestamp\":null,\"labels\":{\"app\":\"test-svc\"},\"name\":\"test-svc\",\"namespace\":\"test1\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":443,\"protocol\":\"TCP\",\"targetPort\":443}],\"selector\":{\"app\":\"test-svc\"},\"type\":\"ClusterIP\"},\"status\":{\"loadBalancer\":{}}}\n"
                    },
                    "creationTimestamp": "2020-02-04T01:16:07Z",
                    "labels": {
                        "app": "test-svc"
                    },
                    "name": "test-svc",
                    "namespace": "test1",
                    "uid": "ebaa71f7-46eb-11ea-85fd-005056a7b324"
                },
                "spec": {
                    "clusterIP": "198.19.241.208",
                    "ports": [
                        {
                            "name": "http",
                            "nodePort": 30100,
                            "port": 443,
                            "protocol": "TCP",
                            "targetPort": 443
                        }
                    ],
                    "selector": {
                        "app": "test-svc"
                    },
                    "sessionAffinity": "None",
                    "type": "NodePort"
                },
                "status": {
                    "loadBalancer": {}
                }
            }
        }
    }
    ns := {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {
            "annotations": {
                "k8s.t-mobile.com/nodeportRange": " 30100, 32000, 33100, 24000 ",
            },
            "creationTimestamp": "2019-07-11T04:38:16Z",
            "labels": {
                "k8s.t-mobile.com/magtape": "enabled"
            },
            "name": "test1",
            "resourceVersion": "468045109",
            "selfLink": "/api/v1/namespaces/test1",
            "uid": "b394f81c-a395-11e9-a86c-005056a71958"
        },
        "spec": {
            "finalizers": [
                "kubernetes"
            ]
        },
        "status": {
            "phase": "Active"
        }
    }

    count(policy_nodeport_range.deny) == 0
    with input as in
    with data.kubernetes.namespaces["test1"] as ns
}

test_np_range_allowed {
    
    in := {
        "apiVersion": "admission.k8s.io/v1beta1",
        "kind": "AdmissionReview",
        "request": {
            "dryRun": false,
            "kind": {
                "group": "",
                "kind": "Service",
                "version": "v1"
            },
            "namespace": "test1",
            "object": {
                "apiVersion": "v1",
                "kind": "Service",
                "metadata": {
                    "annotations": {
                        "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"creationTimestamp\":null,\"labels\":{\"app\":\"test-svc\"},\"name\":\"test-svc\",\"namespace\":\"test1\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":443,\"protocol\":\"TCP\",\"targetPort\":443}],\"selector\":{\"app\":\"test-svc\"},\"type\":\"ClusterIP\"},\"status\":{\"loadBalancer\":{}}}\n"
                    },
                    "creationTimestamp": "2020-02-04T01:16:07Z",
                    "labels": {
                        "app": "test-svc"
                    },
                    "name": "test-svc",
                    "namespace": "test1",
                    "uid": "ebaa71f7-46eb-11ea-85fd-005056a7b324"
                },
                "spec": {
                    "clusterIP": "198.19.241.208",
                    "ports": [
                        {
                            "name": "http",
                            "nodePort": 30150,
                            "port": 443,
                            "protocol": "TCP",
                            "targetPort": 443
                        }
                    ],
                    "selector": {
                        "app": "test-svc"
                    },
                    "sessionAffinity": "None",
                    "type": "NodePort"
                },
                "status": {
                    "loadBalancer": {}
                }
            }
        }
    }
    ns := {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {
            "annotations": {
                "k8s.t-mobile.com/nodeportRange": " 30100-30250 ",
            },
            "creationTimestamp": "2019-07-11T04:38:16Z",
            "labels": {
                "k8s.t-mobile.com/magtape": "enabled"
            },
            "name": "test1",
            "resourceVersion": "468045109",
            "selfLink": "/api/v1/namespaces/test1",
            "uid": "b394f81c-a395-11e9-a86c-005056a71958"
        },
        "spec": {
            "finalizers": [
                "kubernetes"
            ]
        },
        "status": {
            "phase": "Active"
        }
    }

    count(policy_nodeport_range.deny) == 0
    with input as in
    with data.kubernetes.namespaces["test1"] as ns
}

test_np_range_allowed {
    
    in := {
        "apiVersion": "admission.k8s.io/v1beta1",
        "kind": "AdmissionReview",
        "request": {
            "dryRun": false,
            "kind": {
                "group": "",
                "kind": "Service",
                "version": "v1"
            },
            "namespace": "test1",
            "object": {
                "apiVersion": "v1",
                "kind": "Service",
                "metadata": {
                    "annotations": {
                        "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"creationTimestamp\":null,\"labels\":{\"app\":\"test-svc\"},\"name\":\"test-svc\",\"namespace\":\"test1\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":443,\"protocol\":\"TCP\",\"targetPort\":443}],\"selector\":{\"app\":\"test-svc\"},\"type\":\"ClusterIP\"},\"status\":{\"loadBalancer\":{}}}\n"
                    },
                    "creationTimestamp": "2020-02-04T01:16:07Z",
                    "labels": {
                        "app": "test-svc"
                    },
                    "name": "test-svc",
                    "namespace": "test1",
                    "uid": "ebaa71f7-46eb-11ea-85fd-005056a7b324"
                },
                "spec": {
                    "clusterIP": "198.19.241.208",
                    "ports": [
                        {
                            "name": "http",
                            "nodePort": 30187,
                            "port": 443,
                            "protocol": "TCP",
                            "targetPort": 443
                        }
                    ],
                    "selector": {
                        "app": "test-svc"
                    },
                    "sessionAffinity": "None",
                    "type": "NodePort"
                },
                "status": {
                    "loadBalancer": {}
                }
            }
        }
    }
    ns := {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {
            "annotations": {
                "k8s.t-mobile.com/nodeportRange": "30100-30200, 30101,30201,30300-30305, 30180-30305",
            },
            "creationTimestamp": "2019-07-11T04:38:16Z",
            "labels": {
                "k8s.t-mobile.com/magtape": "enabled"
            },
            "name": "test1",
            "resourceVersion": "468045109",
            "selfLink": "/api/v1/namespaces/test1",
            "uid": "b394f81c-a395-11e9-a86c-005056a71958"
        },
        "spec": {
            "finalizers": [
                "kubernetes"
            ]
        },
        "status": {
            "phase": "Active"
        }
    }

    count(policy_nodeport_range.deny) == 0
    with input as in
    with data.kubernetes.namespaces["test1"] as ns
}

test_np_range_one_num_denied {
    
    in := {
        "apiVersion": "admission.k8s.io/v1beta1",
        "kind": "AdmissionReview",
        "request": {
            "dryRun": false,
            "kind": {
                "group": "",
                "kind": "Service",
                "version": "v1"
            },
            "namespace": "test1",
            "object": {
                "apiVersion": "v1",
                "kind": "Service",
                "metadata": {
                    "annotations": {
                        "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"creationTimestamp\":null,\"labels\":{\"app\":\"test-svc\"},\"name\":\"test-svc\",\"namespace\":\"test1\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":443,\"protocol\":\"TCP\",\"targetPort\":443}],\"selector\":{\"app\":\"test-svc\"},\"type\":\"ClusterIP\"},\"status\":{\"loadBalancer\":{}}}\n"
                    },
                    "creationTimestamp": "2020-02-04T01:16:07Z",
                    "labels": {
                        "app": "test-svc"
                    },
                    "name": "test-svc",
                    "namespace": "test1",
                    "uid": "ebaa71f7-46eb-11ea-85fd-005056a7b324"
                },
                "spec": {
                    "clusterIP": "198.19.241.208",
                    "ports": [
                        {
                            "name": "http",
                            "nodePort": 30101,
                            "port": 443,
                            "protocol": "TCP",
                            "targetPort": 443
                        }
                    ],
                    "selector": {
                        "app": "test-svc"
                    },
                    "sessionAffinity": "None",
                    "type": "NodePort"
                },
                "status": {
                    "loadBalancer": {}
                }
            }
        }
    }
    ns := {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {
            "annotations": {
                "k8s.t-mobile.com/nodeportRange": " 30100 ",
            },
            "creationTimestamp": "2019-07-11T04:38:16Z",
            "labels": {
                "k8s.t-mobile.com/magtape": "enabled"
            },
            "name": "test1",
            "resourceVersion": "468045109",
            "selfLink": "/api/v1/namespaces/test1",
            "uid": "b394f81c-a395-11e9-a86c-005056a71958"
        },
        "spec": {
            "finalizers": [
                "kubernetes"
            ]
        },
        "status": {
            "phase": "Active"
        }
    }

    # count(policy_nodeport_range.deny) == 1
    policy_nodeport_range.deny[_] == {
            "errcode": "MT2005",
            "msg": "[FAIL] MED - nodePort 30101 is out of defined range for Service \"test-svc\" (MT2005)",
            "name": "policy-nodeport-range",
            "severity": "MED"
        }
    with input as in
    with data.kubernetes.namespaces["test1"] as ns
}

test_np_range_comma_denied {
    
    in := {
        "apiVersion": "admission.k8s.io/v1beta1",
        "kind": "AdmissionReview",
        "request": {
            "dryRun": false,
            "kind": {
                "group": "",
                "kind": "Service",
                "version": "v1"
            },
            "namespace": "test1",
            "object": {
                "apiVersion": "v1",
                "kind": "Service",
                "metadata": {
                    "annotations": {
                        "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"creationTimestamp\":null,\"labels\":{\"app\":\"test-svc\"},\"name\":\"test-svc\",\"namespace\":\"test1\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":443,\"protocol\":\"TCP\",\"targetPort\":443}],\"selector\":{\"app\":\"test-svc\"},\"type\":\"ClusterIP\"},\"status\":{\"loadBalancer\":{}}}\n"
                    },
                    "creationTimestamp": "2020-02-04T01:16:07Z",
                    "labels": {
                        "app": "test-svc"
                    },
                    "name": "test-svc",
                    "namespace": "test1",
                    "uid": "ebaa71f7-46eb-11ea-85fd-005056a7b324"
                },
                "spec": {
                    "clusterIP": "198.19.241.208",
                    "ports": [
                        {
                            "name": "http",
                            "nodePort": 30101,
                            "port": 443,
                            "protocol": "TCP",
                            "targetPort": 443
                        }
                    ],
                    "selector": {
                        "app": "test-svc"
                    },
                    "sessionAffinity": "None",
                    "type": "NodePort"
                },
                "status": {
                    "loadBalancer": {}
                }
            }
        }
    }
    ns := {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {
            "annotations": {
                "k8s.t-mobile.com/nodeportRange": " 30100, 32000, 33100, 24000 ",
            },
            "creationTimestamp": "2019-07-11T04:38:16Z",
            "labels": {
                "k8s.t-mobile.com/magtape": "enabled"
            },
            "name": "test1",
            "resourceVersion": "468045109",
            "selfLink": "/api/v1/namespaces/test1",
            "uid": "b394f81c-a395-11e9-a86c-005056a71958"
        },
        "spec": {
            "finalizers": [
                "kubernetes"
            ]
        },
        "status": {
            "phase": "Active"
        }
    }

    # count(policy_nodeport_range.deny) == 1
    policy_nodeport_range.deny[_] == {
            "errcode": "MT2005",
            "msg": "[FAIL] MED - nodePort 30101 is out of defined range for Service \"test-svc\" (MT2005)",
            "name": "policy-nodeport-range",
            "severity": "MED"
        }
    with input as in
    with data.kubernetes.namespaces["test1"] as ns
}

test_np_range_range_denied {
    
    in := {
        "apiVersion": "admission.k8s.io/v1beta1",
        "kind": "AdmissionReview",
        "request": {
            "dryRun": false,
            "kind": {
                "group": "",
                "kind": "Service",
                "version": "v1"
            },
            "namespace": "test1",
            "object": {
                "apiVersion": "v1",
                "kind": "Service",
                "metadata": {
                    "annotations": {
                        "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"creationTimestamp\":null,\"labels\":{\"app\":\"test-svc\"},\"name\":\"test-svc\",\"namespace\":\"test1\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":443,\"protocol\":\"TCP\",\"targetPort\":443}],\"selector\":{\"app\":\"test-svc\"},\"type\":\"ClusterIP\"},\"status\":{\"loadBalancer\":{}}}\n"
                    },
                    "creationTimestamp": "2020-02-04T01:16:07Z",
                    "labels": {
                        "app": "test-svc"
                    },
                    "name": "test-svc",
                    "namespace": "test1",
                    "uid": "ebaa71f7-46eb-11ea-85fd-005056a7b324"
                },
                "spec": {
                    "clusterIP": "198.19.241.208",
                    "ports": [
                        {
                            "name": "http",
                            "nodePort": 30075,
                            "port": 443,
                            "protocol": "TCP",
                            "targetPort": 443
                        }
                    ],
                    "selector": {
                        "app": "test-svc"
                    },
                    "sessionAffinity": "None",
                    "type": "NodePort"
                },
                "status": {
                    "loadBalancer": {}
                }
            }
        }
    }
    ns := {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {
            "annotations": {
                "k8s.t-mobile.com/nodeportRange": " 30100-30250 ",
            },
            "creationTimestamp": "2019-07-11T04:38:16Z",
            "labels": {
                "k8s.t-mobile.com/magtape": "enabled"
            },
            "name": "test1",
            "resourceVersion": "468045109",
            "selfLink": "/api/v1/namespaces/test1",
            "uid": "b394f81c-a395-11e9-a86c-005056a71958"
        },
        "spec": {
            "finalizers": [
                "kubernetes"
            ]
        },
        "status": {
            "phase": "Active"
        }
    }

    # count(policy_nodeport_range.deny) == 1
    policy_nodeport_range.deny[_] == {
            "errcode": "MT2005",
            "msg": "[FAIL] MED - nodePort 30075 is out of defined range for Service \"test-svc\" (MT2005)",
            "name": "policy-nodeport-range",
            "severity": "MED"
        }
    with input as in
    with data.kubernetes.namespaces["test1"] as ns
}

test_np_range_combo_denied {
    
    in := {
        "apiVersion": "admission.k8s.io/v1beta1",
        "kind": "AdmissionReview",
        "request": {
            "dryRun": false,
            "kind": {
                "group": "",
                "kind": "Service",
                "version": "v1"
            },
            "namespace": "test1",
            "object": {
                "apiVersion": "v1",
                "kind": "Service",
                "metadata": {
                    "annotations": {
                        "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"creationTimestamp\":null,\"labels\":{\"app\":\"test-svc\"},\"name\":\"test-svc\",\"namespace\":\"test1\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":443,\"protocol\":\"TCP\",\"targetPort\":443}],\"selector\":{\"app\":\"test-svc\"},\"type\":\"ClusterIP\"},\"status\":{\"loadBalancer\":{}}}\n"
                    },
                    "creationTimestamp": "2020-02-04T01:16:07Z",
                    "labels": {
                        "app": "test-svc"
                    },
                    "name": "test-svc",
                    "namespace": "test1",
                    "uid": "ebaa71f7-46eb-11ea-85fd-005056a7b324"
                },
                "spec": {
                    "clusterIP": "198.19.241.208",
                    "ports": [
                        {
                            "name": "http",
                            "nodePort": 30075,
                            "port": 443,
                            "protocol": "TCP",
                            "targetPort": 443
                        }
                    ],
                    "selector": {
                        "app": "test-svc"
                    },
                    "sessionAffinity": "None",
                    "type": "NodePort"
                },
                "status": {
                    "loadBalancer": {}
                }
            }
        }
    }
    ns := {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {
            "annotations": {
                "k8s.t-mobile.com/nodeportRange": "30100-30200, 30101,30201,30300-30305, 30180-30305",
            },
            "creationTimestamp": "2019-07-11T04:38:16Z",
            "labels": {
                "k8s.t-mobile.com/magtape": "enabled"
            },
            "name": "test1",
            "resourceVersion": "468045109",
            "selfLink": "/api/v1/namespaces/test1",
            "uid": "b394f81c-a395-11e9-a86c-005056a71958"
        },
        "spec": {
            "finalizers": [
                "kubernetes"
            ]
        },
        "status": {
            "phase": "Active"
        }
    }

    # count(policy_nodeport_range.deny) == 1
    policy_nodeport_range.deny[_] == {
            "errcode": "MT2005",
            "msg": "[FAIL] MED - nodePort 30075 is out of defined range for Service \"test-svc\" (MT2005)",
            "name": "policy-nodeport-range",
            "severity": "MED"
        }
    with input as in
    with data.kubernetes.namespaces["test1"] as ns
}


test_np_range_extra_symbols_denied {
    
    in := {
        "apiVersion": "admission.k8s.io/v1beta1",
        "kind": "AdmissionReview",
        "request": {
            "dryRun": false,
            "kind": {
                "group": "",
                "kind": "Service",
                "version": "v1"
            },
            "namespace": "test1",
            "object": {
                "apiVersion": "v1",
                "kind": "Service",
                "metadata": {
                    "annotations": {
                        "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"creationTimestamp\":null,\"labels\":{\"app\":\"test-svc\"},\"name\":\"test-svc\",\"namespace\":\"test1\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":443,\"protocol\":\"TCP\",\"targetPort\":443}],\"selector\":{\"app\":\"test-svc\"},\"type\":\"ClusterIP\"},\"status\":{\"loadBalancer\":{}}}\n"
                    },
                    "creationTimestamp": "2020-02-04T01:16:07Z",
                    "labels": {
                        "app": "test-svc"
                    },
                    "name": "test-svc",
                    "namespace": "test1",
                    "uid": "ebaa71f7-46eb-11ea-85fd-005056a7b324"
                },
                "spec": {
                    "clusterIP": "198.19.241.208",
                    "ports": [
                        {
                            "name": "http",
                            "nodePort": 301010,
                            "port": 443,
                            "protocol": "TCP",
                            "targetPort": 443
                        }
                    ],
                    "selector": {
                        "app": "test-svc"
                    },
                    "sessionAffinity": "None",
                    "type": "NodePort"
                },
                "status": {
                    "loadBalancer": {}
                }
            }
        }
    }
    ns := {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {
            "annotations": {
                "k8s.t-mobile.com/nodeportRange": "--30100-30200, ,30101,30201,30300-30305, 30180-30305,-",
            },
            "creationTimestamp": "2019-07-11T04:38:16Z",
            "labels": {
                "k8s.t-mobile.com/magtape": "enabled"
            },
            "name": "test1",
            "resourceVersion": "468045109",
            "selfLink": "/api/v1/namespaces/test1",
            "uid": "b394f81c-a395-11e9-a86c-005056a71958"
        },
        "spec": {
            "finalizers": [
                "kubernetes"
            ]
        },
        "status": {
            "phase": "Active"
        }
    }

    # count(policy_nodeport_range.deny) == 0
    policy_nodeport_range.deny[_] ==  {
            "errcode": "MT2005",
            "msg": "[FAIL] MED - nodePort 301010 is out of defined range for Service \"test-svc\" (MT2005)",
            "name": "policy-nodeport-range",
            "severity": "MED"
        }
    with input as in
    with data.kubernetes.namespaces["test1"] as ns
}

test_np_range_denied_alpha {
    
    in := {
        "apiVersion": "admission.k8s.io/v1beta1",
        "kind": "AdmissionReview",
        "request": {
            "dryRun": false,
            "kind": {
                "group": "",
                "kind": "Service",
                "version": "v1"
            },
            "namespace": "test1",
            "object": {
                "apiVersion": "v1",
                "kind": "Service",
                "metadata": {
                    "annotations": {
                        "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"creationTimestamp\":null,\"labels\":{\"app\":\"test-svc\"},\"name\":\"test-svc\",\"namespace\":\"test1\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":443,\"protocol\":\"TCP\",\"targetPort\":443}],\"selector\":{\"app\":\"test-svc\"},\"type\":\"ClusterIP\"},\"status\":{\"loadBalancer\":{}}}\n"
                    },
                    "creationTimestamp": "2020-02-04T01:16:07Z",
                    "labels": {
                        "app": "test-svc"
                    },
                    "name": "test-svc",
                    "namespace": "test1",
                    "uid": "ebaa71f7-46eb-11ea-85fd-005056a7b324"
                },
                "spec": {
                    "clusterIP": "198.19.241.208",
                    "ports": [
                        {
                            "name": "http",
                            "nodePort": 30187,
                            "port": 443,
                            "protocol": "TCP",
                            "targetPort": 443
                        }
                    ],
                    "selector": {
                        "app": "test-svc"
                    },
                    "sessionAffinity": "None",
                    "type": "NodePort"
                },
                "status": {
                    "loadBalancer": {}
                }
            }
        }
    }
    ns := {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {
            "annotations": {
                "k8s.t-mobile.com/nodeportRange": " unknown",
            },
            "creationTimestamp": "2019-07-11T04:38:16Z",
            "labels": {
                "k8s.t-mobile.com/magtape": "enabled"
            },
            "name": "test1",
            "resourceVersion": "468045109",
            "selfLink": "/api/v1/namespaces/test1",
            "uid": "b394f81c-a395-11e9-a86c-005056a71958"
        },
        "spec": {
            "finalizers": [
                "kubernetes"
            ]
        },
        "status": {
            "phase": "Active"
        }
    }

    # count(policy_nodeport_range.deny) == 0
    policy_nodeport_range.deny[_] == {
            "errcode": "MT2005",
            "msg": "[FAIL] MED - Invalid data in nodePort annotation in \"test1\" namespace (MT2005)",
            "name": "policy-nodeport-range",
            "severity": "MED"
        }
    with input as in
    with data.kubernetes.namespaces["test1"] as ns
}

test_np_range_sym_denied {
    
    in := {
        "apiVersion": "admission.k8s.io/v1beta1",
        "kind": "AdmissionReview",
        "request": {
            "dryRun": false,
            "kind": {
                "group": "",
                "kind": "Service",
                "version": "v1"
            },
            "namespace": "test1",
            "object": {
                "apiVersion": "v1",
                "kind": "Service",
                "metadata": {
                    "annotations": {
                        "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"creationTimestamp\":null,\"labels\":{\"app\":\"test-svc\"},\"name\":\"test-svc\",\"namespace\":\"test1\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":443,\"protocol\":\"TCP\",\"targetPort\":443}],\"selector\":{\"app\":\"test-svc\"},\"type\":\"ClusterIP\"},\"status\":{\"loadBalancer\":{}}}\n"
                    },
                    "creationTimestamp": "2020-02-04T01:16:07Z",
                    "labels": {
                        "app": "test-svc"
                    },
                    "name": "test-svc",
                    "namespace": "test1",
                    "uid": "ebaa71f7-46eb-11ea-85fd-005056a7b324"
                },
                "spec": {
                    "clusterIP": "198.19.241.208",
                    "ports": [
                        {
                            "name": "http",
                            "nodePort": 30187,
                            "port": 443,
                            "protocol": "TCP",
                            "targetPort": 443
                        }
                    ],
                    "selector": {
                        "app": "test-svc"
                    },
                    "sessionAffinity": "None",
                    "type": "NodePort"
                },
                "status": {
                    "loadBalancer": {}
                }
            }
        }
    }
    ns := {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {
            "annotations": {
                "k8s.t-mobile.com/nodeportRange": "30100&20302",
            },
            "creationTimestamp": "2019-07-11T04:38:16Z",
            "labels": {
                "k8s.t-mobile.com/magtape": "enabled"
            },
            "name": "test1",
            "resourceVersion": "468045109",
            "selfLink": "/api/v1/namespaces/test1",
            "uid": "b394f81c-a395-11e9-a86c-005056a71958"
        },
        "spec": {
            "finalizers": [
                "kubernetes"
            ]
        },
        "status": {
            "phase": "Active"
        }
    }


    # count(policy_nodeport_range.deny) == 0
    policy_nodeport_range.deny[_] == {
            "errcode": "MT2005",
            "msg": "[FAIL] MED - Invalid data in nodePort annotation in \"test1\" namespace (MT2005)",
            "name": "policy-nodeport-range",
            "severity": "MED"
        }
    with input as in
    with data.kubernetes.namespaces["test1"] as ns
}

test_np_range_exempt_allowed {
    
    in := {
        "apiVersion": "admission.k8s.io/v1beta1",
        "kind": "AdmissionReview",
        "request": {
            "dryRun": false,
            "kind": {
                "group": "",
                "kind": "Service",
                "version": "v1"
            },
            "namespace": "test1",
            "object": {
                "apiVersion": "v1",
                "kind": "Service",
                "metadata": {
                    "annotations": {
                        "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Service\",\"metadata\":{\"annotations\":{},\"creationTimestamp\":null,\"labels\":{\"app\":\"test-svc\"},\"name\":\"test-svc\",\"namespace\":\"test1\"},\"spec\":{\"ports\":[{\"name\":\"http\",\"port\":443,\"protocol\":\"TCP\",\"targetPort\":443}],\"selector\":{\"app\":\"test-svc\"},\"type\":\"ClusterIP\"},\"status\":{\"loadBalancer\":{}}}\n"
                    },
                    "creationTimestamp": "2020-02-04T01:16:07Z",
                    "labels": {
                        "app": "test-svc"
                    },
                    "name": "test-svc",
                    "namespace": "test1",
                    "uid": "ebaa71f7-46eb-11ea-85fd-005056a7b324"
                },
                "spec": {
                    "clusterIP": "198.19.241.208",
                    "ports": [
                        {
                            "name": "http",
                            "nodePort": 30187,
                            "port": 443,
                            "protocol": "TCP",
                            "targetPort": 443
                        }
                    ],
                    "selector": {
                        "app": "test-svc"
                    },
                    "sessionAffinity": "None",
                    "type": "NodePort"
                },
                "status": {
                    "loadBalancer": {}
                }
            }
        }
    }
    ns := {
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {
            "annotations": {
                "k8s.t-mobile.com/nodeportRange": "NA",
            },
            "creationTimestamp": "2019-07-11T04:38:16Z",
            "labels": {
                "k8s.t-mobile.com/magtape": "enabled"
            },
            "name": "test1",
            "resourceVersion": "468045109",
            "selfLink": "/api/v1/namespaces/test1",
            "uid": "b394f81c-a395-11e9-a86c-005056a71958"
        },
        "spec": {
            "finalizers": [
                "kubernetes"
            ]
        },
        "status": {
            "phase": "Active"
        }
    }


    count(policy_nodeport_range.deny) == 0
    with input as in
    with data.kubernetes.namespaces["test1"] as ns
}
