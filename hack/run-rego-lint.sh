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



# Check if there are policy files that need to be formatted
unformatted_policies=$(opa fmt -l policies/)

if [ -z "${unformatted_policies}" ]; then

    echo "Rego files are formatted correctly."

else

    echo "The following Rego files need to be formatted. Please run \"make lint-rego\""
    echo
    echo "${unformatted_policies}"
    echo
    opa fmt -d policies/
    echo
    exit 1

fi
