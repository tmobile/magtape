#!/usr/bin/env bash

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

INIT="./app/magtape-init/magtape-init.py"
APP="./app/magtape/magtape.py"
MANIFEST_DIR="./deploy/manifests"
POLICY_DIR="./policies"
INSTALL_MANIFEST="./deploy/install.yaml"
NAMESPACE="magtape-system"

# Start with blank file
> "${INSTALL_MANIFEST}"

# Aggregate MagTape Application specific manifests
cat "${MANIFEST_DIR}/magtape-ns.yaml" >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"
echo "---" >> "${INSTALL_MANIFEST}"
cat "${MANIFEST_DIR}/magtape-cluster-rbac.yaml" >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"
echo "---" >> "${INSTALL_MANIFEST}"
cat "${MANIFEST_DIR}/magtape-ns-rbac.yaml" >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"
echo "---" >> "${INSTALL_MANIFEST}"
cat "${MANIFEST_DIR}/magtape-sa.yaml" >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"
echo "---" >> "${INSTALL_MANIFEST}"
kubectl create cm magtape-init -n "${NAMESPACE}" --from-file=magtape-init="${INIT}" --dry-run -o yaml >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"
echo "---" >> "${INSTALL_MANIFEST}"
kubectl create cm magtape-app -n "${NAMESPACE}" --from-file=magtape-app="${APP}" --dry-run -o yaml >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"
echo "---" >> "${INSTALL_MANIFEST}"
cat "${MANIFEST_DIR}/magtape-env-cm.yaml" >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"
echo "---" >> "${INSTALL_MANIFEST}"
kubectl create cm magtape-vwc-template -n "${NAMESPACE}" --from-file=magtape-vwc="${MANIFEST_DIR}/magtape-vwc.yaml" --dry-run -o yaml >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"
echo "---" >> "${INSTALL_MANIFEST}"
cat "${MANIFEST_DIR}/magtape-opa-cm.yaml" >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"
echo "---" >> "${INSTALL_MANIFEST}"
cat "${MANIFEST_DIR}/magtape-opa-entrypoint-cm.yaml" >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"
echo "---" >> "${INSTALL_MANIFEST}"
cat "${MANIFEST_DIR}/magtape-svc.yaml" >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"
echo "---" >> "${INSTALL_MANIFEST}"
cat "${MANIFEST_DIR}/magtape-pdb.yaml" >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"
echo "---" >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"
cat "${MANIFEST_DIR}/magtape-deploy.yaml"  >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"
echo "---" >> "${INSTALL_MANIFEST}"
echo >> "${INSTALL_MANIFEST}"

# Aggregate MagTape policy manifests
for policy in $(ls ${POLICY_DIR}/*.rego); do

    policy_name="$(echo "${policy}" | sed 's/.*\/\(.*\)\.rego/\1/')"

    kubectl -n ${NAMESPACE} create cm ${policy_name} --from-file=${policy} --dry-run -o yaml |\
    kubectl label --local app=opa openpolicyagent.org/policy=rego -f - --dry-run -o yaml >> "${INSTALL_MANIFEST}"
    echo "---" >> "${INSTALL_MANIFEST}"
    echo >> "${INSTALL_MANIFEST}"
  
done