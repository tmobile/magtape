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

RUN_TYPE="${1}"
TEST_RESOURCE_TYPE="${2}"
TEST_TYPE="${3}"
TEST_NAMESPACE="${4}"
TESTS_MANIFEST="testing/functional-tests.yaml"

################################################################################
#### Functions #################################################################
################################################################################

# **********************************************
# Check the argument being passed to script
# **********************************************
help_message() {

  echo "You need to specify the proper arguments:"
  echo "    Actions Type: (\"test\" or \"clean\")"
  echo "    Test Resource Type: (\"all\", or \"deployments\", \"pdbs\", \"statefulsets\", etc.)"
  echo "    Test Type: (\"all\", \"pass\", or \"fail\")"
  echo "    Test Namespace: (\"test1\")"

}

# **********************************************
# Check the argument being passed to script
# **********************************************
check_arguments() {

  if [ "${RUN_TYPE}" == "" ] || [ "${TEST_RESOURCE_TYPE}" == "" ] || [ "${TEST_TYPE}" == "" ] || [ "${TEST_NAMESPACE}" == "" ]; then

    help_message
    exit 1

  elif [ "${RUN_TYPE}" != "test" ] && [ "${RUN_TYPE}" != "clean" ]; then 

    help_message
    exit 1

  elif [ "${TEST_TYPE}" != "pass" ] && [ "${TEST_TYPE}" != "fail" ] && [ "${TEST_TYPE}" != "all" ]; then

    help_message
    exit 1

  fi

}

# **********************************************
# Run tests/cleanup
# **********************************************
run_resource_tests() {

    local action="${1}"
    local resource="${2}"
    local test_type="${3}"
    local manifest_list=$(yq read -P "${TESTS_MANIFEST}" "resources.[name==${resource}].tests.${test_type}" | sed 's/^-[ ]*//')

    if [ "${manifest_list}" == "" ]; then

      echo "[WARN] No \"${test_type}\" tests for \"${resource}\". Skipping..."
      echo "============================================================================"

    else

      echo "[INFO] **** Running \"${test_type}\" tests for \"${resource}\" ****"
      echo "============================================================================"

      for testfile in ${manifest_list}; do

          local test_file_path="testing/${resource}/${testfile}"

          if [ -f "${test_file_path}" ]; then

              echo "[INFO] ${action}: \"${testfile}\""
              
              kubectl ${action} -f "${test_file_path}" -n ${TEST_NAMESPACE}
              local exit_code=$?

              if [ "${action}" == "apply" ]; then

                  if [ "${test_type}"  == "pass" ] && [ ${exit_code} -ne 0 ]; then

                      echo "[ERROR] Test did not pass. Exiting..."
                      exit 1

                  elif [ "${test_type}"  == "fail" ] && [ ${exit_code} -ne 1 ]; then

                      echo "[ERROR] Test did not pass. Exiting..."
                      exit 1

                  else

                      echo "[INFO] Test Passed"

                  fi

              fi

          else

              echo "[WARN] File \"${test_file_path}\" not found. Skipping..."

          fi

          echo "============================================================================"
          
      done

    fi

}

# **********************************************
# Determine test scope
# **********************************************
scope_and_run_tests() {

  local action="${1}"

  if [ "${TEST_RESOURCE_TYPE}" == "all" ]; then

    resources=$(yq read "${TESTS_MANIFEST}" 'resources.[*].name')

    for resource in ${resources}; do

      if [ "${TEST_TYPE}" == "all" ]; then

        run_resource_tests "${action}" "${resource}" "pass"
        run_resource_tests "${action}" "${resource}" "fail"

      else

        run_resource_tests "${action}" "${resource}" "${TEST_TYPE}"

      fi

    done

  else

    if [ "${TEST_TYPE}" == "all" ]; then

        run_resource_tests "${action}" "${resource}" "pass"
        run_resource_tests "${action}" "${resource}" "fail"

    else

      run_resource_tests "${action}" "${resource}" "${TEST_TYPE}"

    fi

  fi
}

################################################################################
#### Main ######################################################################
################################################################################

check_arguments

case ${RUN_TYPE} in 

  test)
      scope_and_run_tests "apply"
      ;;
  clean)
      scope_and_run_tests "delete"
      ;;
       *)
      help_message
      ;; 
esac

