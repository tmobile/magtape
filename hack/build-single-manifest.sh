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

################################################################################
#### Variables, Arrays, and Hashes #############################################
################################################################################

MODE="${1}"
MANIFEST_DIR="./deploy/manifests"
POLICY_DIR="./policies"
TMP_DIR="./tmp"
INSTALL_MANIFEST="./deploy/install.yaml"
TMP_INSTALL_MANIFEST="${TMP_DIR}/install.yaml"
TARGET_MANIFEST=""
NAMESPACE="magtape-system"

################################################################################
#### Functions #################################################################
################################################################################

# **********************************************
# Check the argument being passed to script
# **********************************************
help_message() {

  echo "You need to specify the proper argument:"
  echo "    Mode: (\"build\" or \"compare\")"

}

# **********************************************
# Check the argument being passed to script
# **********************************************
check_arguments() {

  if [ "${MODE}" == "" ] && [ "${MODE}" != "build" ] && [ "${MODE}" != "compare" ]; then

    help_message
    exit 1

  fi

}

# **********************************************
# Build a single manifest from individuals
# **********************************************
function build_manifest() {

    # Start with blank file
    > "${TARGET_MANIFEST}"

    # Aggregate MagTape Application specific manifests
    cat "${MANIFEST_DIR}/magtape-ns.yaml" >> "${TARGET_MANIFEST}"
    echo >> "${TARGET_MANIFEST}"
    echo "---" >> "${TARGET_MANIFEST}"
    cat "${MANIFEST_DIR}/magtape-cluster-rbac.yaml" >> "${TARGET_MANIFEST}"
    echo >> "${TARGET_MANIFEST}"
    echo "---" >> "${TARGET_MANIFEST}"
    cat "${MANIFEST_DIR}/magtape-ns-rbac.yaml" >> "${TARGET_MANIFEST}"
    echo >> "${TARGET_MANIFEST}"
    echo "---" >> "${TARGET_MANIFEST}"
    cat "${MANIFEST_DIR}/magtape-sa.yaml" >> "${TARGET_MANIFEST}"
    echo >> "${TARGET_MANIFEST}"
    echo "---" >> "${TARGET_MANIFEST}"
    cat "${MANIFEST_DIR}/magtape-env-cm.yaml" >> "${TARGET_MANIFEST}"
    echo >> "${TARGET_MANIFEST}"
    echo "---" >> "${TARGET_MANIFEST}"
    kubectl create cm magtape-vwc-template -n "${NAMESPACE}" --from-file=magtape-vwc="${MANIFEST_DIR}/magtape-vwc.yaml" --dry-run=client -o yaml >> "${TARGET_MANIFEST}"
    echo >> "${TARGET_MANIFEST}"
    echo "---" >> "${TARGET_MANIFEST}"
    cat "${MANIFEST_DIR}/magtape-opa-cm.yaml" >> "${TARGET_MANIFEST}"
    echo >> "${TARGET_MANIFEST}"
    echo "---" >> "${TARGET_MANIFEST}"
    cat "${MANIFEST_DIR}/magtape-opa-entrypoint-cm.yaml" >> "${TARGET_MANIFEST}"
    echo >> "${TARGET_MANIFEST}"
    echo "---" >> "${TARGET_MANIFEST}"
    cat "${MANIFEST_DIR}/magtape-svc.yaml" >> "${TARGET_MANIFEST}"
    echo >> "${TARGET_MANIFEST}"
    echo "---" >> "${TARGET_MANIFEST}"
    cat "${MANIFEST_DIR}/magtape-pdb.yaml" >> "${TARGET_MANIFEST}"
    echo >> "${TARGET_MANIFEST}"
    echo "---" >> "${TARGET_MANIFEST}"
    echo >> "${TARGET_MANIFEST}"
    cat "${MANIFEST_DIR}/magtape-deploy.yaml"  >> "${TARGET_MANIFEST}"
    echo "---" >> "${TARGET_MANIFEST}"
    echo >> "${TARGET_MANIFEST}"
    cat "${MANIFEST_DIR}/magtape-hpa.yaml"  >> "${TARGET_MANIFEST}"
    echo >> "${TARGET_MANIFEST}"
    echo "---" >> "${TARGET_MANIFEST}"
    echo >> "${TARGET_MANIFEST}"

    # Aggregate MagTape policy manifests
    for policy in $(ls ${POLICY_DIR}/*.rego); do

        policy_name="$(echo "${policy}" | sed 's/.*\/\(.*\)\.rego/\1/')"

        kubectl -n ${NAMESPACE} create cm ${policy_name} --from-file=${policy} --dry-run=client -o yaml |\
        kubectl label --local app=opa openpolicyagent.org/policy=rego -f - --dry-run=client -o yaml >> "${TARGET_MANIFEST}"
        echo "---" >> "${TARGET_MANIFEST}"
        echo >> "${TARGET_MANIFEST}"
    
    done

}

################################################################################
#### Main ######################################################################
################################################################################

check_arguments

case ${MODE} in 

    build)

        TARGET_MANIFEST="${INSTALL_MANIFEST}"
        build_manifest
        ;;
  compare)

        TARGET_MANIFEST="${TMP_INSTALL_MANIFEST}"

        # Create temporary directory
        mkdir "${TMP_DIR}"

        build_manifest

        # Compare existing and generated manifest
        if diff "${TMP_INSTALL_MANIFEST}" "${INSTALL_MANIFEST}"; then

            echo "No changes detected"
            EXIT_CODE=0

        else

            echo "Changes detected in manifests. Please run \"make build-single-manifest\" to update install.yaml"
            EXIT_CODE=1

        fi

        # Cleanup temporary directory
        rm -rf "${TMP_DIR}"
        exit "${EXIT_CODE}"
        ;;
        *)
        help_message
        ;; 
esac
