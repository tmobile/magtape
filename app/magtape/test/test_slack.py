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
from requests import Response
import sys
import unittest
from unittest.mock import patch, Mock

sys.path.append("./app/")
from magtape import magtape

class TestSlack(unittest.TestCase):
    def setUp(self):

        self.slack_def_url = os.environ["MAGTAPE_SLACK_WEBHOOK_URL_DEFAULT"]
        self.slack_url_base = "webhook-forwarder.example.com"
        self.sub_value = "https://webhook-forwarder.example.com/services/ABC123/XYZ789"

    def tearDown(self):
        pass

    def test_slack_url_nosub(self):

        """Method to test Slack call with no URL substitution"""

        value = magtape.slack_url_sub(self.slack_def_url)

        self.assertEqual(value, self.slack_def_url)

    def test_slack_url_sub(self):

        """Method to test Slack call with URL substitution"""

        os.environ["SLACK_WEBHOOK_URL_BASE"] = self.slack_url_base

        value = magtape.slack_url_sub(self.slack_def_url)
        self.assertEqual(value, self.sub_value)


if __name__ == "__main__":
    unittest.main()
