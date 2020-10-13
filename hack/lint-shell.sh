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
SELECTION_FILE="hack/.shellcheck-selection"

################################################################################
#### Main ######################################################################
################################################################################

# check to see if being run for ci, if yes exclude legacy scripts from linting
if [[ "ci" == "${RUN_TYPE}" ]]; then

    files_to_check="$(git ls-files --exclude-from=$SELECTION_FILE --ignored)"

else
    
    files_to_check="$(git ls-files --exclude='*.sh' --ignored)"

fi

# variable to count up files that did not lint cleanly
files_with_errors=0

for file in ${files_to_check}; do 

    # run shellcheck, if it doesn't exit clean increment the number of files with errors
    shellcheck --color=auto "${file}" || (( files_with_errors += 1 ))
    
done

# if any of the files didn't come back clean from shellcheck exit with status 1
if (( files_with_errors > 0 )); then

    exit 1

fi
