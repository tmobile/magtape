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
DEPLOY_DIR ?= $(CURDIR)/deploy
POLICY_DIR ?= $(CURDIR)/policies
WEBHOOK_NAMESPACE ?= "magtape-system"
TEST_NAMESPACE ?= "test1"
DOCKER := docker

.PHONY: all
all:

	demo

.PHONY: echo
echo:

	@echo "$(REPO_ROOT)"

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

.PHONY: demo
demo:

	kubectl apply -f $(DEPLOY_DIR)/install.yaml

.PHONY: install
install: demo

.PHONY: uninstall
uninstall:

	kubectl delete -f $(DEPLOY_DIR)/install.yaml
	kubectl delete validatingwebhookconfiguration magtape-webhook
	kubectl delete csr magtape-svc.magtape-system.cert-request

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
coverage: echo

.PHONY: release
release: echo

.PHONY: build-install-manifest
build-install-manifest:

	hack/build-single-manifest.sh

.PHONY: build-magtape-init
build-magtape-init:

	$(DOCKER) build -t tmobile/magtape-init:latest app/magtape-init/

.PHONY: push-magtape-init
push-magtape-init:

	$(DOCKER) push tmobile/magtape-init:latest

.PHONY: build-magtape
build-magtape:

	$(DOCKER) build -t tmobile/magtape:latest app/magtape/

.PHONY: push-magtape
push-magtape:

	$(DOCKER) push tmobile/magtape:latest

.PHONY: build
build: build-magtape-init push-magtape-init build-magtape push-magtape

.PHONY: new-magtape-init
new-magtape-init: build-magtape-init push-magtape-init

.PHONY: new-magtape
new-magtape: build-magtape push-magtape