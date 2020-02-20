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

sys.path.append('./app/')
import magtape

class TestRoutes(unittest.TestCase):

    def setUp(self):

        self.app = magtape.app.test_client()
        self.app.testing = True
        self.k8s_events_enabled = "FALSE"

    def tearDown(self):
        pass

    def test_healthz(self):

        """Method to test webhook /healthz route"""

        result = self.app.get('/healthz')

        self.assertEqual(result.status_code, 200)
        self.assertEqual(json.loads(result.data)["health"], "ok")
        self.assertEqual(json.loads(result.data)["pod_name"], "magtape-abc1234")

    @patch(
        'magtape.build_response_message', 
        return_value = ""
    )
    def test_webhook_all_pass(self, build_response_message_function):

        """Method to test webhook with all fail response from OPA sidecar"""

        with open('./testing/deployments/test-deploy01.json') as json_file:

            request_object_json = json.load(json_file)

            result = self.app.post('/', data=json.dumps(request_object_json), headers={"Content-Type": "application/json"})

            self.assertEqual(result.status_code, 200)
            self.assertEqual(json.loads(result.data)["response"]["allowed"], True)

    @patch('magtape.k8s_events_enabled', "FALSE")
    @patch(
        'magtape.build_response_message', 
        return_value = '[FAIL] HIGH - Found privileged Security Context for container "test-deploy02" (MT2001), [FAIL] LOW - Liveness Probe missing for container "test-deploy02" (MT1001), [FAIL] LOW - Readiness Probe missing for container "test-deploy02" (MT1002), [FAIL] LOW - Resource limits missing (CPU/MEM) for container "test-deploy02" (MT1003), [FAIL] LOW - Resource requests missing (CPU/MEM) for container "test-deploy02" (MT1004)'
    )
    def test_webhook_all_fail(self, build_response_message_function):

        """Method to test webhook with all fail response from OPA sidecar"""

        with open('./testing/deployments/test-deploy02.json') as json_file:

            request_object_json = json.load(json_file)

            result = self.app.post('/', data=json.dumps(request_object_json), headers={"Content-Type": "application/json"})

            self.assertEqual(result.status_code, 200)
            self.assertEqual(json.loads(result.data)["response"]["allowed"], False)
            self.assertEqual(json.loads(result.data)["response"]["status"]["message"], "[FAIL] HIGH - Found privileged Security Context for container \"test-deploy02\" (MT2001), [FAIL] LOW - Liveness Probe missing for container \"test-deploy02\" (MT1001), [FAIL] LOW - Readiness Probe missing for container \"test-deploy02\" (MT1002), [FAIL] LOW - Resource limits missing (CPU/MEM) for container \"test-deploy02\" (MT1003), [FAIL] LOW - Resource requests missing (CPU/MEM) for container \"test-deploy02\" (MT1004)")
 
if __name__ == '__main__':
    unittest.main()
