# Change Log

## 2.1.0

### Overview

This is the intial public release of MagTape. Versions < 2.1.0 were internal only.

## 2.1.1

### Fixes

- Fixed a mistake with the URL used for installation in the Quickstart section of the Readme

# 2.1.2

This release contains several package updates geared towards fixing security related issues with [CVE-2017-18342](https://nvd.nist.gov/vuln/detail/CVE-2017-18342).

 The updated pyyaml package required updates to the Kubernetes Python client library, moving primary support to Kubernetes 1.15+. Backwards compatibility to Kubernetes 1.13 should exist, but isn't tested/gauranteed.

