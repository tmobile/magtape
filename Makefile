# Copyright 2020 T-Mobile, USA, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Trademark Disclaimer: Neither the name of T-Mobile, USA, Inc. nor the names of
# its contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.

MAGTAPE_VERSION := v2.1.5
OPA_VERSION := 0.19.2
KUBE_MGMT_VERSION := 0.11

REPO_ROOT := $(CURDIR)
APP_NAME ?= "magtape.py"
DEPLOY_DIR ?= $(CURDIR)/deploy
POLICY_DIR ?= $(CURDIR)/policies
TESTING_DIR ?= $(CURDIR)/testing
WEBHOOK_NAMESPACE ?= "magtape-system"
TEST_NAMESPACE ?= "test1"
DOCKER := docker

###############################################################################
# K8s Related Targets #########################################################
###############################################################################

# Create Namespace for MagTape
.PHONY: ns-create-magtape
ns-create-magtape:

	kubectl create ns $(WEBHOOK_NAMESPACE)

# Create Namespace for testing
.PHONY: ns-create-test
ns-create-test:

	kubectl create ns $(TEST_NAMESPACE)
	kubectl label ns $(TEST_NAMESPACE) k8s.t-mobile.com/magtape=enabled --overwrite

# Delete Namespace for MagTape
.PHONY: ns-delete-magtape
ns-delete-magtape:

	kubectl delete ns $(WEBHOOK_NAMESPACE)

# Delete Namespace for testing
.PHONY: ns-delete-test
ns-delete-test:

	kubectl delete ns $(TEST_NAMESPACE)

# DEPRECATED - Moved to init application. Will be removed in the future.
.PHONY: cert-gen
cert-gen:

	hack/ssl-cert-gen.sh \
    --service magtape-svc \
    --secret magtape-certs \
    --namespace $(WEBHOOK_NAMESPACE)

# Install MagTape (Demo Install)
.PHONY: install
install:

	kubectl apply -f $(DEPLOY_DIR)/install.yaml

# Uninstall Magtape (Demo Install)
.PHONY: uninstall
uninstall:

	kubectl delete -f $(DEPLOY_DIR)/install.yaml
	kubectl delete validatingwebhookconfiguration magtape-webhook
	kubectl delete csr magtape-svc.magtape-system.cert-request

# Restart Magtape Pods (Demo Install)
.PHONY: restart
restart:

	kubectl rollout restart deploy magtape -n magtape-system

# Cleanup MagTape (Demo Install)
.PHONY: clean
clean: uninstall

###############################################################################
# Python Targets ##############################################################
###############################################################################

# Run unit tests for MagTape/MagTape-Init
.PHONY: unit-python
unit-python:

	hack/run-python-tests.sh

# Run unit tests for MagTape/MagTape-Init
.PHONY: test-python
test-python: unit-python

# Lint Python and update python code
.Phony: lint-python
lint-python:

	black app/magtape-init/
	black app/magtape/

# Verify linting of Python during CI
.PHONY: ci-lint-python
ci-lint-python:

	black --check app/magtape-init/
	black --check app/magtape/

###############################################################################
# Rego Targets ################################################################
###############################################################################

# Run unit tests for MagTape Policies
.PHONY: unit-rego
unit-rego:

	opa test -v policies/

# Check Coverage for MagTape Policy tests
.PHONY: coverage-rego
coverage-rego:

	opa test -c --threshold 80.0 policies/

# Run test suite for MagTape Policies
.PHONY: test-rego
test-rego: unit-rego coverage-rego

# Lint Python and update python code
.Phony: lint-rego
lint-rego:

	opa fmt -l policies/
	opa fmt -w policies/

# Verify linting of Python during CI
.PHONY: ci-lint-rego
ci-lint-rego: 

	hack/run-rego-lint.sh

###############################################################################
# Functional Test Targets #####################################################
###############################################################################

# Run MagTape functional tests for Deployments
.PHONY: test-functional
test-functional:

	hack/run-functional-tests.sh test all all test1

# Run MagTape functional tests for Deployments
.PHONY: test-clean
test-clean:

	hack/run-functional-tests.sh clean all all test1

# Run all unit and functional tests for MagTape/MagTape-Init
.PHONY: test-all
test-all: test test-functional

###############################################################################
# Misc Repo Targets ###########################################################
###############################################################################

# Verify copyright boilerplate in files
.PHONY: boilerplate
boilerplate:

	hack/verify-boilerplate.sh

# Build dmeo install manifest for MagTape
.PHONY: build-single-manifest
build-single-manifest:

	hack/build-single-manifest.sh build

PHONY: compare-single-manifest
compare-single-manifest:

	hack/build-single-manifest.sh compare

# Set release version in deployment manifest
.PHONY: set-release-version
set-release-version:

	sed -i='' "s/\(image: tmobile\/magtape-init:\).*/\1${MAGTAPE_VERSION}/" deploy/manifests/magtape-deploy.yaml
	sed -i='' "s/\(image: tmobile\/magtape:\).*/\1${MAGTAPE_VERSION}/" deploy/manifests/magtape-deploy.yaml
	sed -i='' "s/\(image: openpolicyagent\/opa:\).*/\1${OPA_VERSION}/" deploy/manifests/magtape-deploy.yaml
	sed -i='' "s/\(image: openpolicyagent\/kube-mgmt:\).*/\1${KUBE_MGMT_VERSION}/" deploy/manifests/magtape-deploy.yaml

# Cut new MagTape release
.PHONY: release
release: echo

###############################################################################
# Container Image Targets #####################################################
###############################################################################

# Build MagTape-Init container image
.PHONY: build-magtape-init
build-magtape-init:

	$(DOCKER) build -t tmobile/magtape-init:latest app/magtape-init/

# Push MagTape-Init container image to DockerHub
.PHONY: push-magtape-init
push-magtape-init:

	$(DOCKER) push tmobile/magtape-init:latest

# Build MagTape container image
.PHONY: build-magtape
build-magtape:

	$(DOCKER) build -t tmobile/magtape:latest app/magtape/

# Push MagTape container image to DockerHub
.PHONY: push-magtape
push-magtape:

	$(DOCKER) push tmobile/magtape:latest

# Build and push all MagTape container images to DockerHub
.PHONY: build
build: build-magtape-init push-magtape-init build-magtape push-magtape

# Build and push MagTape-Init container image to DockerHub
.PHONY: new-magtape-init
new-magtape-init: build-magtape-init push-magtape-init

# Build and push MagTape container image to DockerHub
.PHONY: new-magtape
new-magtape: build-magtape push-magtape
