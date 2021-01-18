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
from kubernetes.client.rest import ApiException
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
from unittest.mock import patch, Mock, MagicMock

sys.path.append("./app/")
from magtape import magtape


class TestSlack(unittest.TestCase):
    def setUp(self):

        self.slack_def_url = os.environ["MAGTAPE_SLACK_WEBHOOK_URL_DEFAULT"]
        self.slack_url_base = "webhook-forwarder.example.com"
        self.sub_value = "https://webhook-forwarder.example.com/services/ABC123/XYZ789"
        self.request_namespace = "test-ns"
        self.slack_webhook_secret = "magtape-slack"
        self.slack_webhook_secret_key = "webhook-url"
        self.test_slack_webhook_url = "https://hooks.slack.com/services/ABC123/XYZ789"
        self.alert_targets = {}

    def mock_slack_secret(self):

        secret_metadata = client.V1ObjectMeta(
            name=self.slack_webhook_secret, namespace=self.request_namespace,
        )
        secret_data = {
            self.slack_webhook_secret_key: base64.b64encode(
                self.test_slack_webhook_url.encode("utf8")
            ),
            "key2": base64.b64encode("test-abc123".encode("utf8")),
        }
        secret = client.V1Secret(metadata=secret_metadata, data=secret_data)

        return secret

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

    @patch("magtape.magtape.config.load_incluster_config")
    @patch("magtape.magtape.config.load_kube_config")
    @patch("magtape.magtape.client.CoreV1Api")
    def test_get_namespace_slack_no_in_cluster_k8s_config(
        self, mock_k8s_corev1api, mock_k8s_config, mock_k8s_config_in_cluster
    ):

        """Method to test reading secret containing Slack Incoming Webhook with no in-cluster k8s config"""

        mock_k8s_config_in_cluster.side_effect = config.ConfigException
        mock_k8s_api = mock_k8s_corev1api.return_value
        mock_k8s_api.read_namespaced_secret.return_value = self.mock_slack_secret()
        expected_result = self.test_slack_webhook_url

        value = magtape.get_namespace_slack(
            self.request_namespace, self.slack_webhook_secret,
        )

        self.assertRaises(config.ConfigException)
        self.assertEqual(value, expected_result)
        mock_k8s_config_in_cluster.assert_called_once_with()
        mock_k8s_config.assert_called_once_with()
        mock_k8s_api.read_namespaced_secret.assert_called_once_with(
            self.slack_webhook_secret, self.request_namespace
        )

    @patch("magtape.magtape.config.load_incluster_config")
    @patch("magtape.magtape.config.load_kube_config")
    @patch("magtape.magtape.client.CoreV1Api")
    def test_get_namespace_slack_no_k8s_config(
        self, mock_k8s_corev1api, mock_k8s_config, mock_k8s_config_in_cluster
    ):

        """Method to test reading secret containing Slack Incoming Webhook with no k8s config"""

        mock_k8s_config.side_effect = config.ConfigException
        mock_k8s_config_in_cluster.side_effect = config.ConfigException
        mock_k8s_api = mock_k8s_corev1api.return_value
        mock_k8s_api.read_namespaced_secret.return_value = self.mock_slack_secret()

        with self.assertRaises(Exception):

            magtape.get_namespace_slack(
                self.request_namespace, self.slack_webhook_secret,
            )

        self.assertRaises(config.ConfigException)
        mock_k8s_config.assert_called_once_with()
        mock_k8s_config_in_cluster.assert_called_once_with()
        mock_k8s_corev1api.assert_not_called()

    # Beware...order of patch decorators matters with relation to input arguments.
    # Python processes them bottom up as in:
    #
    # @patch('module.ClassName2')
    # @patch('module.ClassName1')
    # def test(MockClass1, MockClass2):
    #
    # More info here: https://docs.python.org/3/library/unittest.mock.html#quick-guide
    #
    @patch("magtape.magtape.config.load_incluster_config")
    @patch("magtape.magtape.client.CoreV1Api")
    def test_get_namespace_slack_success(self, mock_k8s_corev1api, mock_k8s_config):

        """Method to test reading secret containing Slack Incoming Webhook with success"""

        mock_k8s_api = mock_k8s_corev1api.return_value
        mock_k8s_api.read_namespaced_secret.return_value = self.mock_slack_secret()
        expected_result = self.test_slack_webhook_url

        value = magtape.get_namespace_slack(
            self.request_namespace, self.slack_webhook_secret,
        )

        self.assertEqual(value, expected_result)
        mock_k8s_config.assert_called_once_with()
        mock_k8s_api.read_namespaced_secret.assert_called_once_with(
            self.slack_webhook_secret, self.request_namespace
        )

    @patch("magtape.magtape.config.load_incluster_config")
    @patch("magtape.magtape.client.CoreV1Api")
    def test_get_namespace_slack_exception_notfound(
        self, mock_k8s_corev1api, mock_k8s_config
    ):

        """Method to test reading secret containing Slack Incoming Webhook with Not Found exception"""

        mock_k8s_api = mock_k8s_corev1api.return_value
        mock_k8s_api.read_namespaced_secret.side_effect = ApiException(
            reason="Not Found"
        )
        expected_result = None

        value = magtape.get_namespace_slack(
            self.request_namespace, self.slack_webhook_secret,
        )

        self.assertRaises(ApiException)
        self.assertEqual(value, expected_result)
        mock_k8s_config.assert_called_once_with()
        mock_k8s_api.read_namespaced_secret.assert_called_once_with(
            self.slack_webhook_secret, self.request_namespace
        )

    @patch("magtape.magtape.config.load_incluster_config")
    @patch("magtape.magtape.client.CoreV1Api")
    def test_get_namespace_slack_exception_other(
        self, mock_k8s_corev1api, mock_k8s_config
    ):

        """Method to test reading secret containing Slack Incoming Webhook with Other exception"""

        mock_k8s_api = mock_k8s_corev1api.return_value
        mock_k8s_api.read_namespaced_secret.side_effect = ApiException(reason="Other")
        expected_result = None

        value = magtape.get_namespace_slack(
            self.request_namespace, self.slack_webhook_secret,
        )

        self.assertRaises(ApiException)
        self.assertEqual(value, expected_result)
        mock_k8s_config.assert_called_once_with()
        mock_k8s_api.read_namespaced_secret.assert_called_once_with(
            self.slack_webhook_secret, self.request_namespace
        )

    @patch("magtape.magtape.config.load_incluster_config")
    @patch("magtape.magtape.client.CoreV1Api")
    def test_get_namespace_slack_missing_key(self, mock_k8s_corev1api, mock_k8s_config):

        """Method to test reading secret missing a key for Slack Incoming Webhook"""

        mock_k8s_api = mock_k8s_corev1api.return_value
        mock_k8s_api.read_namespaced_secret.return_value = self.mock_slack_secret()
        del mock_k8s_api.read_namespaced_secret.return_value.data[
            self.slack_webhook_secret_key
        ]
        expected_result = None

        value = magtape.get_namespace_slack(
            self.request_namespace, self.slack_webhook_secret,
        )

        self.assertEqual(value, expected_result)
        mock_k8s_config.assert_called_once_with()
        mock_k8s_api.read_namespaced_secret.assert_called_once_with(
            self.slack_webhook_secret, self.request_namespace
        )

    @patch("magtape.magtape.config.load_incluster_config")
    @patch("magtape.magtape.client.CoreV1Api")
    def test_get_namespace_slack_empty_value(self, mock_k8s_corev1api, mock_k8s_config):

        """Method to test reading secret with empty value for Slack Incoming Webhook"""

        mock_k8s_api = mock_k8s_corev1api.return_value
        mock_k8s_api.read_namespaced_secret.return_value = self.mock_slack_secret()
        mock_k8s_api.read_namespaced_secret.return_value.data[
            self.slack_webhook_secret_key
        ] = ""
        expected_result = None

        value = magtape.get_namespace_slack(
            self.request_namespace, self.slack_webhook_secret,
        )

        self.assertEqual(value, expected_result)
        mock_k8s_config.assert_called_once_with()
        mock_k8s_api.read_namespaced_secret.assert_called_once_with(
            self.slack_webhook_secret, self.request_namespace
        )


if __name__ == "__main__":
    unittest.main()
