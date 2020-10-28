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

## 2.2.0

This release focuses on some security enhancements.

### Enhancements

- Add securityContext and non-root user for pod/containers (#47)
- Hardcode Gunicorn workers/threads to fix #48 (#49)
- Add HPA resource for horizontal scaling (#50)
- Add new framework for executing setup/teardown code between functional tests (#45)

### Misc Notes

- Changes OPA container listening port from `443` to `8443` since a non-root user can't bind to ports below 1000. The OPA container isn't exposed outside of localhost, so this shouldn't present any issues

## 2.2.1

### Security Fix

- Bump cryptography from 2.9.2 to 3.2 in /app/magtape-init (ref #68)

```
* **SECURITY ISSUE:** Attempted to make RSA PKCS#1v1.5 decryption more constant
  time, to protect against Bleichenbacher vulnerabilities. Due to limitations
  imposed by our API, we cannot completely mitigate this vulnerability and a
  future release will contain a new API which is designed to be resilient to
  these for contexts where it is required. Credit to **Hubert Kario** for
  reporting the issue. *CVE-2020-25659*
* Support for OpenSSL 1.0.2 has been removed. Users on older version of OpenSSL
  will need to upgrade.
* Added basic support for PKCS7 signing (including SMIME) via
  :class:`~cryptography.hazmat.primitives.serialization.pkcs7.PKCS7SignatureBuilder`.
.. _v3-1-1:


3.1.1 - 2020-09-22
```

### Enhancements

- Backported some CI changes related to Image Builds (ref #62)
