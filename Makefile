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

REPO_ROOT := $(CURDIR)
APP_NAME ?= "magtape.py"
APP_DIR ?= "$(CURDIR)/app"
DEPLOY_DIR ?= "$(CURDIR)/deploy"
POLICY_DIR ?= "$(CURDIR)/policies"
CLUSTER_NAME ?= "cluster1"
WEBHOOK_NAMESPACE ?= "magtape-system"
TEST_NAMESPACE ?= "test1"


SHELL := /bin/bash

.PHONY: all
all:

	demo

.PHONY: echo
echo:

	@echo "$(REPO_ROOT)"

# Create Namespace for MagTape
.PHONY: ns-create-magtape
ns-create-magtape:

	@kubectl create ns $(WEBHOOK_NAMESPACE); \
  	kubectl label ns $(WEBHOOK_NAMESPACE) openpolicyagent.org/policy=rego --overwrite

# Create Namespace for testing
.PHONY: ns-create-test
ns-create-test:

	@kubectl create ns $(TEST_NAMESPACE); \
  	kubectl label ns $(TEST_NAMESPACE) k8s.t-mobile.com/magtape=enabled --overwrite

# Delete Namespace for MagTape
.PHONY: ns-delete-magtape
ns-delete-magtape:

	kubectl delete ns $(WEBHOOK_NAMESPACE)

# Delete Namespace for testing
.PHONY: ns-delete-test
ns-delete-test:

	kubectl delete ns $(TEST_NAMESPACE)

.PHONY: cert-gen
cert-gen:

	hack/ssl-cert-gen.sh \
    --service magtape-svc \
    --secret magtape-certs \
    --namespace $(WEBHOOK_NAMESPACE)

.PHONY: demo
demo:
	hack/magtape-install.sh install 

.PHONY: install
install: demo

.PHONY: uninstall
uninstall:

	hack/magtape-install.sh delete

.PHONY: clean
clean: uninstall

.PHONY: unit
unit:

	hack/run_tests.sh

.PHONY: test-functional
test-functional:

	testing/test-deploy.sh test

.PHONY: test
test: unit

.PHONY: test-all
test-all: test test-functional

.PHONY: coverage
covergae: echo

.PHONY: release
release: echo
