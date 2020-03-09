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

#set -x

################################################################################
#### Variables, Arrays, and Hashes #############################################
################################################################################

RUN_TYPE="${1}"
APP_NAME="magtape.py"
APP_DIR="./app"
DEPLOY_DIR="./deploy"
POLICY_DIR="./policies"
CLUSTER_NAME="cluster1"
WEBHOOK_NAMESPACE="magtape-system"
TEST_NAMESPACE="test1"

################################################################################
#### Functions #################################################################
################################################################################

# **********************************************
# Print help info
# **********************************************
help_message() {

  echo "You need to specify an argument (\"install\" or \"delete\")"

}

# **********************************************
# Check the argument being passed to script
# **********************************************
check_arguments() {

  if [ "${RUN_TYPE}" == "" ]; then

    help_message
    exit 1

  fi

}

build_manifests() {

  # Takes one argument that should be either "apply" or "delete"
  local action="${1}"

  kubectl -n "${WEBHOOK_NAMESPACE}" apply -f "${DEPLOY_DIR}"

  #kubectl -n "${WEBHOOK_NAMESPACE}" apply -f "${DEPLOY_DIR}" --dry-run  -o yaml | \
  #sed -e "s/==CA_BUNDLE==/${CA_BUNDLE}/g" |\
  #kubectl -n "${WEBHOOK_NAMESPACE}" "${action}" -f -

}

# **********************************************
# Run install routine
# **********************************************
magtape_install() {

  # Create Namespace for OPA
  kubectl create ns ${WEBHOOK_NAMESPACE}
  kubectl label ns ${WEBHOOK_NAMESPACE} openpolicyagent.org/policy=rego --overwrite

  # Create Namespace for testing
  kubectl create ns ${TEST_NAMESPACE}
  kubectl label ns ${TEST_NAMESPACE} k8s.t-mobile.com/magtape=enabled --overwrite

  # Setup ClusterRoles/ClusterRoleBindings
  #kubectl auth reconcile -f "${DEPLOY_DIR}/magtape-cluster-rbac.yaml"

  # Setup SSL stuff
  #hack/ssl-cert-gen.sh \
  #  --service magtape-svc \
  #  --secret magtape-certs \
  #  --namespace ${WEBHOOK_NAMESPACE}
    
  CA_BUNDLE=$(kubectl get cm -n kube-system extension-apiserver-authentication -o=jsonpath='{.data.client-ca-file}' | base64 | tr -d '\n')

  # Setup Python app in ConfigMap
  kubectl -n ${WEBHOOK_NAMESPACE} create cm magtape-cm --from-file=script="${APP_DIR}/magtape.py" --dry-run -o yaml | kubectl apply -f -

  # Apply MagTape
  build_manifests "apply"

  # Create ConfigMaps for OPA Policies
  for policy in `ls ${POLICY_DIR}/*.rego`; do

    policy_name="$(echo "${policy}" | sed 's/.*\/\(.*\)\.rego/\1/')"

    kubectl -n ${WEBHOOK_NAMESPACE} create cm ${policy_name} --from-file=${policy}
    kubectl -n ${WEBHOOK_NAMESPACE} label cm ${policy_name} app=opa --overwrite
    kubectl -n ${WEBHOOK_NAMESPACE} label cm ${policy_name} openpolicyagent.org/policy=rego --overwrite
  
  done

  echo "Waiting for configMaps to register with OPA"
  sleep 20

  kubectl get cm -n ${WEBHOOK_NAMESPACE} -l app=opa -o jsonpath="{range .items[*]}{.metadata.name}{\"\t\t\"}{.metadata.annotations.openpolicyagent\.org/policy-status}{\"\n\"}"

}

# **********************************************
# Run delete routine
# **********************************************
magtape_delete() {

  CA_BUNDLE=$(kubectl get cm -n kube-system extension-apiserver-authentication -o=jsonpath='{.data.client-ca-file}' | base64 | tr -d '\n')

  # Delete MagTape
  build_manifests "delete"

  #kubectl delete -f "${DEPLOY_DIR}/magtape-cluster-rbac.yaml"

  kubectl delete ns ${WEBHOOK_NAMESPACE} --grace-period=0
  kubectl delete ns ${TEST_NAMESPACE} --grace-period=0

}

################################################################################
#### Main ######################################################################
################################################################################

check_arguments

case ${RUN_TYPE} in 

  install)
      magtape_install
      ;;
  delete)
      magtape_delete
      ;;
       *)
      help_message
      ;; 
esac
