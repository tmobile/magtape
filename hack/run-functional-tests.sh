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
TEST_RESOURCE_KIND="${2}"
TEST_RESOURCE_DESIRED="${3}"
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

  if [ "${RUN_TYPE}" == "" ] || [ "${TEST_RESOURCE_KIND}" == "" ] || [ "${TEST_RESOURCE_DESIRED}" == "" ] || [ "${TEST_NAMESPACE}" == "" ]; then

    help_message
    exit 1

  elif [ "${RUN_TYPE}" != "test" ] && [ "${RUN_TYPE}" != "clean" ]; then 

    help_message
    exit 1

  elif [ "${TEST_RESOURCE_DESIRED}" != "pass" ] && [ "${TEST_RESOURCE_DESIRED}" != "fail" ] && [ "${TEST_RESOURCE_DESIRED}" != "all" ]; then

    help_message
    exit 1

  fi

}

# **********************************************
# Run tests/cleanup
# **********************************************
run_resource_tests() {
  
  # define local action from first argument
  local action="${1}"

  # define local index from second argument
  local resource_index="${2}"

  # grab local resource from ${TESTS_MANIFEST}
  local resource
  
  resource=$(yq read "${TESTS_MANIFEST}" "resources.[${resource_index}].kind")

  # grab local test type from ${TESTS_MANIFEST}
  local test_type
  
  test_type=$(yq read "${TESTS_MANIFEST}" "resources.[${resource_index}].desired")

  # grab local length of the list of test manifests to use
  local manifest_array_length
  
  manifest_array_length=$(yq read -l "${TESTS_MANIFEST}" "resources.[${resource_index}].manifests")

  # grab local user_script specified for pre/post/between running
  local user_script
  
  user_script=$(yq read -P "${TESTS_MANIFEST}" "resources.[${resource_index}].script")

  # full path to the user specified script associate with this stanza in the manifest
  local user_script_path="testing/${resource}/scripts/${user_script}"

  if (( manifest_array_length == 0 )); then

    echo "[WARN] No \"${test_type}\" tests for \"${resource}\". Skipping..."
    echo "============================================================================"

  else

    echo "[INFO] **** Running \"${test_type}\" tests for \"${resource}\" ****"
    echo "============================================================================"

    # check to see if the user specified a script to be associated with this stanza
    # only run script for apply actions
    if [[ "${user_script}" != "" ]] && [[ "${action}" == "apply" ]]; then 

      # if they did specify a script run it with the setup argument and pass the namespace in
      "${user_script_path}" "setup" "${TEST_NAMESPACE}"

      echo "============================================================================"

    fi

    for ((manifest_index = 0 ; manifest_index < manifest_array_length ; manifest_index++)); do

        # declare testfile as local
        local testfile
        
        # try getting the name of the file using the new style 'file' map key
        testfile=$(yq read -P "${TESTS_MANIFEST}" "resources.[${resource_index}].manifests.[${manifest_index}].file")

        # declare file_description as local
        local file_description
        
        # get the file_description with 'name 'map key
        file_description=$(yq read -P "${TESTS_MANIFEST}" "resources.[${resource_index}].manifests.[${manifest_index}].name")

        # declare test_file_path as local
        local test_file_path
        
        # create the relative path to the test file (from 'file' map key)
        test_file_path="testing/${resource}/${testfile}"
        
        # check if the file exists at the correct relative path; 
        # if it doesn't try falling back to the legacy style where the array index contains the filename instead of a map
        if [[ -z "${testfile}" ]]; then

            testfile=$(yq read -P "${TESTS_MANIFEST}" "resources.[${resource_index}].manifests.[${manifest_index}]")

        fi

        # declare test_file_path as local
        local test_file_path
        
        # create the relative path to the test file (from 'file' map key)
        test_file_path="testing/${resource}/${testfile}"

        # make sure the file exists using the legacy style name; if it doesn't then we're skipping this file
        if [ -f "${test_file_path}" ]; then

            # check if file_description is empty, if it is fall back to the older output
            if [ -z "${file_description}" ]; then

                echo "[INFO] ${action}: \"${testfile}\""

            else

                echo "[INFO] ${file_description}"

            fi
            
            if [ "${action}" == "delete" ]; then
              
              # kubectl doesn't like double quotes here.
              # disable checking for double quotes around variables.
              # shellcheck disable=SC2086
              kubectl ${action} -f "${test_file_path}" -n ${TEST_NAMESPACE} --ignore-not-found

            else

              # kubectl doesn't like double quotes here.
              # disable checking for double quotes around variables
              # shellcheck disable=SC2086
              kubectl ${action} -f "${test_file_path}" -n ${TEST_NAMESPACE}

            fi

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

            # try to warn that the functional test manifest has a problem with one of the file definitions
            echo "[WARN] File \"${testfile}\" not found in directory \"testing/${resource}/\". Functional Testing Failed..."

            exit 1

        fi

        # check to see if the user specified a script to be associated with this stanza
        # only run script for apply actions
        if [[ "${user_script}" != "" ]] && [[ "${action}" == "apply" ]]; then

          # if they did specify a script run it with the between argument and pass the namespace in
          "${user_script_path}" "between" "${TEST_NAMESPACE}"

        fi

        echo "============================================================================"
        
    done

    # check to see if the user specified a script to be associated with this stanza
    # only run script for apply actions
    if [[ "${user_script}" != "" ]] && [[ "${action}" == "apply" ]]; then

      # if they did specify a script run it with the teardown argument and pass the namespace in
      "${user_script_path}" "teardown" "${TEST_NAMESPACE}"

      echo "============================================================================"

    fi

  fi

}

# **********************************************
# Determine test scope
# **********************************************
scope_and_run_tests() {

  # create identifiable local variable for argument 1, the action to perform
  local action="${1}"

  # size the array of resources
  local resource_array_length
  resource_array_length=$(yq read -l "${TESTS_MANIFEST}" 'resources')


  # loop through all resources in the supplied manifest
  # determine which indicies meet the supplied criteria in ${TEST_RESOURCE_KIND} and ${TEST_RESOURCE_DESIRED}
  for ((i = 0 ; i < resource_array_length ; i++)); do

    # check if we're doing all resources or if the resource kind at $i matches the requested kind
    # double brackets are technically correct; the BEST kind of correct!
    if [[ "${TEST_RESOURCE_KIND}" == "all" ]] || [[ "${TEST_RESOURCE_KIND}" == "$(yq read "${TESTS_MANIFEST}" "resources.[${i}].kind")" ]]; then

      # check if we're doing all desired results or if the resoured desired result at $i matches the requested desired result
      if [[ "${TEST_RESOURCE_DESIRED}" == "all" ]] || [[ "${TEST_RESOURCE_DESIRED}" == "$(yq read "${TESTS_MANIFEST}" "resources.[${i}].desired")" ]]; then

        run_resource_tests "${action}" "${i}"
      fi

    fi

  done

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

