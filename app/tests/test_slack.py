#!/usr/bin/env python

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
from requests import Response
import sys
import unittest
from unittest.mock import patch, Mock

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
from magtape import slack_url_sub

class TestSlack(unittest.TestCase):

    def setUp(self):

        self.slack_def_url = os.environ["MAGTAPE_SLACK_WEBHOOK_URL_DEFAULT"]
        self.slack_url_base = "webhook-forwarder.example.com"
        self.sub_value = "https://webhook-forwarder.example.com/services/ABC123/XYZ789"

    def tearDown(self):
        pass

    def test_slack_url_nosub(self):

        value = slack_url_sub(self.slack_def_url)

        self.assertEqual(value, self.slack_def_url)

    
    def test_slack_url_sub(self):

        os.environ['SLACK_WEBHOOK_URL_BASE'] = self.slack_url_base

        value = slack_url_sub(self.slack_def_url)
        self.assertEqual(value, self.sub_value)
 
if __name__ == '__main__':
    unittest.main()