#!/usr/bin/env bash

# Copyright 2019 T-Mobile.
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

################################################################################
#### Variables, Arrays, and Hashes #############################################
################################################################################

RUN_TYPE="${1}"
TESTFILE_DIR="./deployments"
TEST_NAMESPACE="default"

################################################################################
#### Functions #################################################################
################################################################################

# **********************************************
# Check the argument being passed to script
# **********************************************
help_message() {

  echo "You need to specify an argument (\"test\" or \"cleanup\")"

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

# **********************************************
# Run tests/cleanup
# **********************************************
run_tests() {

    COMMAND="${1}"

    for testfile in $(ls ${TESTFILE_DIR}/test-deploy*.yaml); do 

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
  cleanup)
      run_tests "delete"
      ;;
       *)
      help_message
      ;; 
esac

