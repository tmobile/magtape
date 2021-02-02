# Testing Info

Below is a list of test files to use with testing various features and scenarios of the MagTape tool. Most of the test files should also have associated JSON files:

- YAML File - Used for applying directly to a Kubernetes cluster
- JSON Request Object File - Used for testing the MagTape application outside of Kubernetes
- JSON Response File - Used for validating responses from various functions/calls of the MagTape application

Some files listed below don't exist yet. They are listed for tracking purposes and will be added in the future.

## Functional Tests

Every policy for MagTape should have one or more functional tests associated with it. Functional tests are typically YAML manifests for Kubernetes resources with specific configuration to test the functionality of a policy. Manifests should be placed in the a directory associated with the target resource type (ie. `./testing/deployments/`, `./testing/services/`, etc.). 

The [functional-tests.yaml](./functional-tests.yaml) file contains the tests that get executed within the CI workflows and what results are expected (pass or fail). Each test should fall under the appropriate resource and result section of the file. The script field can be used to specify a bash script which can be used to execute setup, teardown and between (each manifest being applied) tasks to modify the environment making it suitable for executing the test. 

- **Setup** tasks would be run before any of the manifests of a specific kind/desired combination are run. 
- **Teardown** would run after the kind/desired combination's manifests have been tested. 
- **Between** is run in between applying each manifest for the associated kind/desired combination. 

An [example script](https://gist.github.com/ilrudie/43823733444ba7976b2f567f30706620) can be used as a starting point for implementing these setup, teardown and between functions for your tests.

```yaml
resources:
  - kind: deployments
    desired: pass
    script:
    manifests:
      - name: "Deployment - Pass all policies"
        file: test-deploy01.yaml
      - name: "Deployment - No Liveness Probe"
        file: test-deploy03.yaml
  - kind: deployments
    desired: fail
    script: 
    manifests:
      - name: "Deployment - Fail all policies"
        file: test-deploy02.yaml
```
