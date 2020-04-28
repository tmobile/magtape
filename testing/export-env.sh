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

export MAGTAPE_NAMESPACE_NAME="magtape-system"
export MAGTAPE_POD_NAME="magtape-abc1234"
export MAGTAPE_CLUSTER_NAME="test-cluster"
export MAGTAPE_K8S_EVENTS_ENABLED="TRUE"
export MAGTAPE_SLACK_ENABLED="FALSE"
export MAGTAPE_SLACK_PASSIVE="FALSE"
export MAGTAPE_SLACK_WEBHOOK_URL_DEFAULT="https://slacky.slack.slack"
export MAGTAPE_SLACK_ANNOTATION="magtape/slack-webhook-url"
export MAGTAPE_SLACK_CHANNEL="test"
export MAGTAPE_SLACK_USER="test"
export MAGTAPE_SLACK_ICON=":magtape:"
export MAGTAPE_DENY_LEVEL="LOW"
export MAGTAPE_LOG_LEVEL="INFO"
export OPA_BASE_URL="http://127.0.0.1:8181"
export OPA_K8S_PATH="/v0/data/magtape"
