package kubernetes.admission.test_policy_pdb

import data.kubernetes.admission.policy_pdb

test_pdb_allowed_min {
    in := {
        "apiVersion": "policy/v1beta1",
        "kind": "PodDisruptionBudget",
        "metadata": {
            "name": "test1-pdb"
        },
        "request" : {
            "object": {
                "spec": {
                    "minAvailable": "66%",
                    "selector": {
                    "matchLabels": {
                        "app": "test1"
                    }
                    }
                }
            }
        }
    }

    count(policy_pdb.deny) == 0 with input as in
}

test_pdb_allowed_min {
    in := {
        "apiVersion": "policy/v1beta1",
        "kind": "PodDisruptionBudget",
        "metadata": {
            "name": "test1-pdb"
        },
        "request" : {
            "object": {
                "spec": {
                    "maxUnavailable": "33%",
                    "selector": {
                    "matchLabels": {
                        "app": "test1"
                    }
                    }
                }
            }
        }
    }

    count(policy_pdb.deny) == 0 with input as in
}

test_pdb_denied_min {
    in := {
        "apiVersion": "policy/v1beta1",
        "kind": "PodDisruptionBudget",
        "metadata": {
            "name": "test1-pdb"
        },
        "request" : {
            "object": {
                "spec": {
                    "minAvailable": "67%",
                    "selector": {
                    "matchLabels": {
                        "app": "test1"
                    }
                    }
                }
            }
        }
    }

    # count(policy_pdb.deny) == 1 with input as in
    policy_pdb.deny[_] ==   {
            "errcode": "MT1005",
            "msg": "[FAIL] HIGH - Value (67%) for \"minAvailable\" not within range 0%-66% (MT1005)",
            "name": "policy-pdb",
            "severity": "HIGH"
        }
    with input as in
}

test_pdb_denied_min_int {
    in := {
        "apiVersion": "policy/v1beta1",
        "kind": "PodDisruptionBudget",
        "metadata": {
            "name": "test1-pdb"
        },
        "request" : {
            "object": {
                "spec": {
                    "minAvailable": "10",
                    "selector": {
                    "matchLabels": {
                        "app": "test1"
                    }
                    }
                }
            }
        }
    }

    # count(policy_pdb.deny) == 1 with input as in
    policy_pdb.deny[_] == {
            "errcode": "MT1005",
            "msg": "[FAIL] HIGH - Value \"10\" for \"minAvailable\" should be a Percentage, not an Integer (MT1005)",
            "name": "policy-pdb",
            "severity": "HIGH"
        }
    with input as in
}


test_pdb_denied_max_int {
    in := {
        "apiVersion": "policy/v1beta1",
        "kind": "PodDisruptionBudget",
        "metadata": {
            "name": "test1-pdb"
        },
        "request" : {
            "object": {
                "spec": {
                    "maxUnavailable": "10",
                    "selector": {
                    "matchLabels": {
                        "app": "test1"
                    }
                    }
                }
            }
        }
    }

    # count(policy_pdb.deny) == 1 with input as in
    policy_pdb.deny[_] == {
            "errcode": "MT1005",
            "msg": "[FAIL] HIGH - Value \"10\" for \"maxUnavailable\" should be a Percentage, not an Integer (MT1005)",
            "name": "policy-pdb",
            "severity": "HIGH"
        }
    with input as in
}

test_pdb_denied_max {
    in := {
        "apiVersion": "policy/v1beta1",
        "kind": "PodDisruptionBudget",
        "metadata": {
            "name": "test1-pdb"
        },
        "request" : {
            "object": {
                "spec": {
                    "maxUnavailable": "32%",
                    "selector": {
                    "matchLabels": {
                        "app": "test1"
                    }
                    }
                }
            }
        }
    }

    # count(policy_pdb.deny) == 1 with input as in
    policy_pdb.deny[_] == {
            "errcode": "MT1005",
            "msg": "[FAIL] HIGH - Value (32%) for \"maxUnavailable\" not within range 33%-100% (MT1005)",
            "name": "policy-pdb",
            "severity": "HIGH"
        }
    with input as in
}
