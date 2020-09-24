# Change Log

## 2.1.0

### Overview

This is the intial public release of MagTape. Versions < 2.1.0 were internal only.

## 2.1.1

### Fixes

- Fixed a mistake with the URL used for installation in the Quickstart section of the Readme

## 2.1.2

This release contains several package updates geared towards fixing security related issues with [CVE-2017-18342](https://nvd.nist.gov/vuln/detail/CVE-2017-18342).

 The updated pyyaml package required updates to the Kubernetes Python client library, moving primary support to Kubernetes 1.15+. Backwards compatibility to Kubernetes 1.13 should exist, but isn't tested/gauranteed.

## 2.1.3

This release migrates to using the Gunicorn WSGI HTTP Server instead of the default Flask server. This change reduces average latency by about 75% in our normal benchmarking tests. This change also means the standar 3 replica deployment can handle almost 3 times the request rate as before.

## 2.1.4

This release adds the `approve` verb to the RBAC config to account for newer changes to the Kubernetes certificates/CSR API as noted [here](https://github.com/kubernetes/kubernetes/pull/86933). These changes were tested against K8s 1.14, 1.15, 1.16, 1.17, and 1.18.

## 2.1.5

This release adds new policies and enhances several CI workflow components.

### New Policies

- Singleton Pods (Check ID: MT1007)
- Host Port (Check ID: MT1008)
- emptyDir Volume (Check ID: MT1009)
- Host Path (Check ID: MT1010)
- Node Port Range (Check ID: MT2002)

### New CI Features

- Kubernetes Matrix for end-to-end testing. All commits/PR's are now tested against Kubernetes 1.16, 1.17, 1.18, and 1.19
- Rego linting and unit tests
- Code quality anallysis and static code scanning for Security/Best Practices

### Misc Enhancements

- Enhancements for Advanced install workflow with Kustomize