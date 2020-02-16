#!/usr/bin/env python

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

from flask import Flask, request, jsonify
from kubernetes import client, config
from pprint import pprint
import base64
import copy
import datetime
import json
import os
import re
import requests
import sys
import unittest
from unittest.mock import patch

os.environ["MAGTAPE_POD_NAME"] = "magtape-abc1234"
os.environ["MAGTAPE_CLUSTER_NAME"] = "cluster1"
os.environ["MAGTAPE_DASHBOARD_BASE_DOMAIN"] = "example.com"
os.environ["MAGTAPE_SLACK_ENABLED"] = "FALSE"
os.environ["MAGTAPE_SLACK_PASSIVE"] = "FALSE"
os.environ["MAGTAPE_SLACK_WEBHOOK_URL_DEFAULT"] = "https://hooks.slack.com/services/ABC123/XYZ789"
os.environ["MAGTAPE_SLACK_ANNOTATION"] = "magtape/slack-webhook-url"
os.environ["MAGTAPE_SLACK_CHANNEL"] = "test"
os.environ["MAGTAPE_SLACK_USER"] = "test"
os.environ["MAGTAPE_SLACK_ICON"] = ":magtape:"
os.environ["MAGTAPE_DENY_LEVEL"] = "LOW"
os.environ["MAGTAPE_LOG_LEVEL"] = "INFO"
os.environ["MAGTAPE_K8S_EVENTS_ENABLED"] = "TRUE"
os.environ["OPA_BASE_URL"] = "http://127.0.0.1:8181"
os.environ["OPA_K8S_PATH"] = "/v0/data/magtape"

sys.path.append('./../app/')
from magtape import build_response_message

class TestRoutes(unittest.TestCase):

    def setUp(self):
        pass

    def tearDown(self):
        pass

    @patch('requests.post')
    def test_opa_success(self, mock_post):

        mock_post.return_value.status_code = 200
        mock_post.return_value.headers = r"""{'Content-Type': 'application/json', 'Date': 'Mon, 19 Aug 2019 22:55:37 GMT', 'Content-Length': '1078'}"""
        mock_post.return_value.text = r"""{"decisions":[{"policy":"policy_resource_limits","reasons":[{"errcode":"MT1003","msg":"[FAIL] LOW - Resource limits missing (CPU/MEM) for container \"test-deploy02\" (MT1003)","name":"policy-resource-limits","severity":"LOW"}]},{"policy":"policy_privileged_pod","reasons":[{"errcode":"MT2001","msg":"[FAIL] HIGH - Found privileged Security Context for container \"test-deploy02\" (MT2001)","name":"policy-privileged-pod","severity":"HIGH"}]},{"policy":"policy_readiness_probe","reasons":[{"errcode":"MT1002","msg":"[FAIL] LOW - Readiness Probe missing for container \"test-deploy02\" (MT1002)","name":"policy-readiness-probe","severity":"LOW"}]},{"policy":"policy_resource_requests","reasons":[{"errcode":"MT1004","msg":"[FAIL] LOW - Resource requests missing (CPU/MEM) for container \"test-deploy02\" (MT1004)","name":"policy-resource-requests","severity":"LOW"}]},{"policy":"policy_liveness_probe","reasons":[{"errcode":"MT1001","msg":"[FAIL] LOW - Liveness Probe missing for container \"test-deploy02\" (MT1001)","name":"policy-liveness-probe","severity":"LOW"}]}]}"""

        with open('../testing/deployments/test-deploy02.json') as json_file:

            request_object_json = json.load(json_file)

            response_message = ""

            result = build_response_message(request_object_json, response_message)

            expected_result = '[FAIL] HIGH - Found privileged Security Context for container "test-deploy02" (MT2001), [FAIL] LOW - Liveness Probe missing for container "test-deploy02" (MT1001), [FAIL] LOW - Readiness Probe missing for container "test-deploy02" (MT1002), [FAIL] LOW - Resource limits missing (CPU/MEM) for container "test-deploy02" (MT1003), [FAIL] LOW - Resource requests missing (CPU/MEM) for container "test-deploy02" (MT1004)'

            print(f"Result is: {result}")

            self.assertEqual(result, expected_result)

    @patch('requests.post')
    def test_opa_exception(self, mock_post):

        mock_post.return_value.exceptions.ConnectionError("Some exception when calling OPA")
        mock_post.return_value.headers = r"""{'Content-Type': 'application/json', 'Date': 'Mon, 19 Aug 2019 22:55:37 GMT', 'Content-Length': '1078'}"""
        #mock_post.return_value

        with open('../testing/deployments/test-deploy02.json') as json_file:

            request_object_json = json.load(json_file)

            response_message = ""

            result = build_response_message(request_object_json, response_message)

            expected_result = '[FAIL] HIGH - Call to OPA was unsuccessful. Please contact your cluster administrator'

            print(f"Result is: {result}")

            self.assertEqual(result, expected_result)

    @patch('requests.post')
    def test_opa_404(self, mock_post):

        mock_post.return_value.headers = r"""{'Content-Type': 'application/json', 'Date': 'Mon, 19 Aug 2019 22:55:37 GMT', 'Content-Length': '1078'}"""
        mock_post.return_value.status_code = 404

        with open('../testing/deployments/test-deploy02.json') as json_file:

            request_object_json = json.load(json_file)

            response_message = ""

            result = build_response_message(request_object_json, response_message)

            expected_result = '[FAIL] HIGH - Call to OPA was unsuccessful. Please contact your cluster administrator'

            print(f"Result is: {result}")

            self.assertEqual(result, expected_result)

