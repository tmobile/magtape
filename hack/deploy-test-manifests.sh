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
TESTFILE_DIR="${2}"
TEST_NAMESPACE="${3}"

################################################################################
#### Functions #################################################################
################################################################################

# **********************************************
# Check the argument being passed to script
# **********************************************
help_message() {

  echo "You need to specify the proper arguments:"
  echo "    Actions Type: (\"test\" or \"clean\")"
  echo "    Test File Directory: (\"./testing/deployments\")"
  echo "    Test Namespace: (\"test1\""

}

# **********************************************
# Check the argument being passed to script
# **********************************************
check_arguments() {

  if [ "${RUN_TYPE}" == "" ] || [ "${TESTFILE_DIR}" == "" ] || [ "${TEST_NAMESPACE}" == "" ]; then

    help_message
    exit 1

  fi

}

# **********************************************
# Run tests/cleanup
# **********************************************
run_tests() {

    COMMAND="${1}"

    for testfile in $(ls ${TESTFILE_DIR}/test-*.yaml); do 

        echo "============================================================================"
        echo "[INFO] ${COMMAND}: \"${testfile}\""
        kubectl ${COMMAND} -f ${testfile} -n ${TEST_NAMESPACE}
        
    done

}

################################################################################
#### Main ######################################################################
################################################################################

check_arguments

case ${RUN_TYPE} in 

  test)
      run_tests "apply"
      ;;
  clean)
      run_tests "delete"
      ;;
       *)
      help_message
      ;; 
esac

