# Testing Info

Below are a list of test files to use with testing various features and scenarios of the MagTape tool. Most of the test files should have associated JSON files:

- YAML File - Used for applying directly to a Kubernetes cluster
- JSON Request Object File - Used for testing the MagTape application outside of Kubernetes
- JSON Response File - Used for validating responses from various functions/calls of the MagTape application

## Test Samples Available

| File                               | Test Type                                      |
|---                                 |---                                             |
| **Pod Tests**                                                                       |
| test-pod01.yaml                  | POD, singleton                                 |
| test-pod02.yaml                  | POD, singleton, privileged                     |
| **Deployment Tests**                                                                |
| [test-deploy01.yaml](./deployments/test-deploy01.yaml)        | DEPLOYMENT, pass all policies                  |
| [test-deploy02.yaml](./deployments/test-deploy02.yaml)        | DEPLOYMENT, fail all policies                  |
| [test-deploy03.yaml](./deployments/test-deploy03.yaml)        | DEPLOYMENT, no liveness probe                  |
| [test-deploy04.yaml](./deployments/test-deploy04.yaml)        | DEPLOYMENT, no readiness probe                 |
| [test-deploy05.yaml](./deployments/test-deploy05.yaml)        | DEPLOYMENT, no CPU requests                    |
| [test-deploy06.yaml](./deployments/test-deploy06.yaml)        | DEPLOYMENT, no MEM requests                    |
| [test-deploy07.yaml](./deployments/test-deploy07.yaml)        | DEPLOYMENT, no CPU limits                      |
| [test-deploy08.yaml](./deployments/test-deploy08.yaml)        | DEPLOYMENT, no MEM limits                      |
| [test-deploy09.yaml](./deployments/test-deploy09.yaml)        | DEPLOYMENT, no CPU or MEM requests             |
| [test-deploy10.yaml](./deployments/test-deploy10.yaml)        | DEPLOYMENT, no CPU or MEM limits               |
| [test-deploy11.yaml](./deployments/test-deploy11.yaml)        | DEPLOYMENT, multiple containers                |
| **Statefulset Tests**                                                               |
| test-sts01.yaml        | STATEFULSET, pass all policies                 |
| test-sts02.yaml        | STATEFULSET, fail all policies                 |
| **Daemonset Tests**                                                                 |
| test-ds01.yaml         | DAEMONSET, pass all policies                   |
| test-ds02.yaml         | DAEMONSET, fail all policies                   |
| **PDB Tests**                                                                       |
| [test-pdb01.yaml](./testing/pdbs/test-pdb01.yaml)                    | PDB, minAvailable, Integer value               |
| [test-pdb02.yaml](./testing/pdbs/test-pdb02.yaml)                    | PDB, minAvailable, Percent in range            |
| [test-pdb03.yaml](./testing/pdbs/test-pdb03.yaml)                    | PDB, minAvailable, Percent out or range        |
| [test-pdb04.yaml](./testing/pdbs/test-pdb04.yaml)                    | PDB, maxUnavailable, Integer value             |
| [test-pdb05.yaml](./testing/pdbs/test-pdb05.yaml)                    | PDB, maxUnavailable, Percent in range          |
| [test-pdb06.yaml](./testing/pdbs/test-pdb06.yaml)                    | PDB, maxUnavailable, Percent out or range      |

## Regression Tests

These are various scenarios that have been tested at some point in time and should eventually have automated tests

- Test deploying a singleton pod
- Test deploying workload that contains multiple containers
- Test deploying workload without liveness/readiness
- Test deploying workload with a privileged security context
- Test deploying workload with liveness/readiness & privileged security context
- Test deploying workload to namespace without Slack Webhook URL annotation
- Test deploying workload to namespace with Slack Webhook URL annotation
- Test deploying workload to namespace without Webhook Enabled label
- Test deploying workload to namespace with Webhook Enabled label
- Test PDB samples listed above
