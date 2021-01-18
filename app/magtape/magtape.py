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
from logging.handlers import MemoryHandler
from prometheus_client import Counter
from prometheus_flask_exporter import PrometheusMetrics
import base64
import copy
import datetime
import json
import logging
import os
import re
import requests
import sys
import time

app = Flask(__name__)

# Setup Prometheus Metrics for Flask app
metrics = PrometheusMetrics(app, defaults_prefix="magtape")

# Static information as metric
metrics.info("app_info", "Application info", version="v2.2.0")

# Set logging config
log = logging.getLogger("werkzeug")
log.disabled = True
magtape_log_level = os.environ["MAGTAPE_LOG_LEVEL"]
app.logger.setLevel(magtape_log_level)

# Set Global variables
cluster = os.environ["MAGTAPE_CLUSTER_NAME"]
magtape_namespace_name = os.environ["MAGTAPE_NAMESPACE_NAME"]
magtape_pod_name = os.environ["MAGTAPE_POD_NAME"]

# Set Slack related variables
slack_enabled = os.environ["MAGTAPE_SLACK_ENABLED"]
slack_passive = os.environ["MAGTAPE_SLACK_PASSIVE"]
slack_webhook_url_default = os.getenv("MAGTAPE_SLACK_WEBHOOK_URL_DEFAULT", "")
slack_webhook_secret = "magtape-slack"
slack_webhook_secret_key = "webhook-url"
slack_user = os.environ["MAGTAPE_SLACK_USER"]
slack_icon = os.environ["MAGTAPE_SLACK_ICON"]

# Set K8s Events specific variables
k8s_events_enabled = os.environ["MAGTAPE_K8S_EVENTS_ENABLED"]

# Set OPA Info
opa_base_url = os.environ["OPA_BASE_URL"]
opa_k8s_path = os.environ["OPA_K8S_PATH"]
opa_url = opa_base_url + opa_k8s_path

# Set Deny Level
magtape_deny_level = os.environ["MAGTAPE_DENY_LEVEL"]

# Set Custom Prometheus Counters
# Request Metrics represent requests to the MagTape API
magtape_metrics_requests = Counter(
    "magtape_requests",
    "Request Metrics for MagTape",
    ["count_type", "ns", "alert_sent"],
)
# Policy metrics represent individual policy evaluations
magtape_metrics_policies = Counter(
    "magtape_policy", "Policy Metrics for MagTape", ["count_type", "policy", "ns"]
)

################################################################################
################################################################################
################################################################################


@app.route("/", methods=["POST"])
def webhook():

    """Function to call main logic and return k8s admission response"""

    request_info = request.json
    request_spec = copy.deepcopy(request_info)

    # Call Main Webhook function
    admissionReview = magtape(request_spec)

    # Return JSON formatted response object
    return jsonify(admissionReview)


################################################################################
################################################################################
################################################################################


@app.route("/healthz", methods=["GET"])
def healthz():

    """Function to return health info for app"""

    health_response = {
        "pod_name": magtape_pod_name,
        "date_time": str(datetime.datetime.now()),
        "health": "ok",
    }

    # Return JSON formatted response object
    return jsonify(health_response)


################################################################################
################################################################################
################################################################################


def magtape(request_spec):

    """main function"""

    # Zero out specific info per call
    is_allowed = True
    skip_alert = False
    response_message = ""
    alert_should_send = False
    alert_targets = {}
    customer_alert_sent = False
    k8s_object_owner_kind = None
    k8s_object_owner_name = None

    # Set Object specific info from request
    uid = request_spec["request"]["uid"]
    workload = request_spec["request"]["object"]["metadata"]["name"]
    workload_type = request_spec["request"]["kind"]["kind"]
    namespace = request_spec["request"]["namespace"]
    request_user = request_spec["request"]["userInfo"]["username"]

    app.logger.info(
        "##################################################################"
    )
    app.logger.info(f"Deny Level: {magtape_deny_level}")
    app.logger.info(f"Processing {workload_type}: {namespace}/{workload}")
    app.logger.info(f"Request User: {request_user}")
    app.logger.debug(
        f"Request Object: \n{json.dumps(request_spec, indent=2, sort_keys=True)}"
    )

    if (
        "ownerReferences" in request_spec["request"]["object"]["metadata"]
        and request_spec["request"]["object"]["metadata"]["ownerReferences"][0]["kind"]
        == "ReplicaSet"
    ):

        # Set Owner Info
        k8s_object_owner_kind = request_spec["request"]["object"]["metadata"][
            "ownerReferences"
        ][0]["kind"]
        k8s_object_owner_name = request_spec["request"]["object"]["metadata"][
            "ownerReferences"
        ][0]["name"]

        # Set Skip for Alert
        skip_alert = True

    else:

        # Run MagTape Specific checks on requests objects
        response_message = build_response_message(
            request_spec, response_message, namespace
        )

        # Output policy decision
        for policy_response in response_message.split(", "):

            if policy_response:

                app.logger.info(policy_response)

            else:

                app.logger.info("[PASS] All checks")

    app.logger.debug(f"Skip Alert: {skip_alert}")

    # Set is_allowed value based on DENY_LEVEL and response_message content
    if magtape_deny_level == "OFF":

        app.logger.debug("Deny level detected: OFF")

        is_allowed = True

    elif magtape_deny_level == "LOW":

        DENY_LIST = ["[FAIL] HIGH"]

        app.logger.debug("Deny level detected: LOW")

        if any(denyword in response_message for denyword in DENY_LIST):

            app.logger.debug("Sev Fail level: HIGH")

            is_allowed = False
            alert_should_send = True

    elif magtape_deny_level == "MED":

        DENY_LIST = ["[FAIL] HIGH", "[FAIL] MED"]

        app.logger.debug("Deny level detected: MED")

        if any(denyword in response_message for denyword in DENY_LIST):

            app.logger.debug("Sev Fail level: HIGH/MED")

            is_allowed = False
            alert_should_send = True

    elif magtape_deny_level == "HIGH":

        DENY_LIST = ["[FAIL] HIGH", "[FAIL] MED", "[FAIL] LOW"]

        app.logger.debug("Deny level detected: HIGH")

        if any(denyword in response_message for denyword in DENY_LIST):

            app.logger.debug("Sev Fail level: HIGH/MED/LOW")

            is_allowed = False
            alert_should_send = True

    else:

        app.logger.debug("Deny level detected: NONE")

        is_allowed = False
        alert_should_send = True

    # Set optional message if is_allowed = false
    if is_allowed:

        admission_response = {
            "uid": uid,
            "allowed": is_allowed,
            "warnings": response_message.split(", "),
        }

    else:

        admission_response = {
            "uid": uid,
            "allowed": is_allowed,
            "warnings": response_message.split(", "),
            "status": {"message": response_message},
        }

    # Create K8s Event for target namespace if enabled
    if k8s_events_enabled == "TRUE":

        app.logger.info("K8s Event are enabled")

        if "FAIL" in response_message or alert_should_send:

            send_k8s_event(
                magtape_pod_name, namespace, workload_type, workload, response_message
            )

    else:

        app.logger.info("K8s Events are NOT enabled")

    # Send Slack message when failure is detected if enabled
    if slack_enabled == "TRUE":

        app.logger.info("Slack alerts are enabled")

        if skip_alert:

            app.logger.info(
                f'Skipping alert for child object of previously validated parent "{k8s_object_owner_kind}/{k8s_object_owner_name}"'
            )

        elif (
            "FAIL" in response_message and slack_passive == "TRUE" or alert_should_send
        ):

            # Add default Webhook URL to alert Targets
            alert_targets["default"] = slack_webhook_url_default

            # Check Request namespace for custom Slack Webhook
            namespace_slack = get_namespace_slack(namespace, slack_webhook_secret)

            if namespace_slack:

                alert_targets["namespace"] = namespace_slack

            # Set boolean to show whether a customer alert was sent
            if len(alert_targets) > 1:

                customer_alert_sent = True

            # Send alerts to all target Slack Webhooks
            for slack_target_type, slack_target in alert_targets.items():

                if slack_target:

                    send_slack_alert(
                        response_message,
                        slack_target_type,
                        slack_target,
                        slack_user,
                        slack_icon,
                        cluster,
                        namespace,
                        workload,
                        workload_type,
                        request_user,
                        customer_alert_sent,
                        magtape_deny_level,
                        is_allowed,
                    )

                else:

                    app.logger.info(
                        f"Slack target ({slack_target_type}) is blank. Skipping alert(s)"
                    )

            # Increment Prometheus Counters
            if is_allowed:

                magtape_metrics_requests.labels(
                    count_type="allowed", ns=namespace, alert_sent="true"
                ).inc()
                magtape_metrics_requests.labels(
                    count_type="total", ns=namespace, alert_sent="true"
                ).inc()

            else:

                magtape_metrics_requests.labels(
                    count_type="denied", ns=namespace, alert_sent="true"
                ).inc()
                magtape_metrics_requests.labels(
                    count_type="total", ns=namespace, alert_sent="true"
                ).inc()

    else:

        app.logger.info(f"Slack alerts are NOT enabled")

        # Increment Prometheus Counters
        if is_allowed:

            magtape_metrics_requests.labels(
                count_type="allowed", ns=namespace, alert_sent="false"
            ).inc()
            magtape_metrics_requests.labels(
                count_type="total", ns=namespace, alert_sent="false"
            ).inc()

        else:

            magtape_metrics_requests.labels(
                count_type="denied", ns=namespace, alert_sent="false"
            ).inc()
            magtape_metrics_requests.labels(
                count_type="total", ns=namespace, alert_sent="false"
            ).inc()

    # Build Admission Response
    admissionReview = {
        "apiVersion": "admission.k8s.io/v1beta1",
        "kind": "AdmissionReview",
        "response": admission_response,
    }

    app.logger.info("Sending Response to K8s API Server")
    app.logger.debug(
        f"Admission Review: \n{json.dumps(admissionReview, indent=2, sort_keys=True)}"
    )

    return admissionReview


################################################################################
################################################################################
################################################################################


def build_response_message(object_spec, response_message, namespace):

    """Function to build the response message used to inform users of policy decisions"""

    try:

        opa_response = requests.post(
            opa_url,
            json=object_spec,
            headers={"Content-Type": "application/json"},
            timeout=5,
        )

    except requests.exceptions.RequestException as exception:

        app.logger.info(f"Call to OPA was unsuccessful")

        print(f"Exception:\n{exception}")

        response_message = "[FAIL] HIGH - Call to OPA was unsuccessful. Please contact your cluster administrator"

        return response_message

    if opa_response and opa_response.status_code == 200:

        app.logger.info("Call to OPA was successful")
        app.logger.debug(f"Opa Response Headers: {opa_response.headers}")
        app.logger.debug(f"OPA Response Text:\n{opa_response.text}")

    else:

        app.logger.info(
            f"Request to OPA returned an error {opa_response.status_code}, the response is:\n{opa_response.text}"
        )

        response_message = "[FAIL] HIGH - Call to OPA was unsuccessful. Please contact your cluster administrator"

        return response_message

    # Load OPA request results as JSON
    opa_response_json = json.loads(opa_response.text)["decisions"]

    app.logger.debug(f"OPA JSON:\n{opa_response_json}")

    # Build response message from "msg" component of each object in the OPA response
    messages = []

    # Note this entire statement can likely be broken down into a simpler chained
    # generator/list comprehension statement.....I tried, but couldn't get it to work
    # Something similar to:
    # opa_response_msg = ", ".join(reason['msg'] for reason in decision['reasons'] for decision in opa_response_json)
    for decision in opa_response_json:

        for reason in decision["reasons"]:

            messages.append(reason["msg"])

    # Sort messages for consistent output
    messages.sort()

    opa_response_msg = ", ".join(messages)

    # Cleanup artifacts from OPA response before sending to K8s API
    response_message = re.sub(r"^\[\'|\'\]$|\'(\, )\'", r"\1", opa_response_msg)

    app.logger.debug(f"response_message:\n{response_message}")

    # Increment Prometheus counter for each policy object in the OPA response
    for policy_obj in opa_response_json:

        policy_name = re.sub("policy-", "", policy_obj["policy"]).replace("_", "-")

        app.logger.debug(f"Policy Object: {policy_obj}")
        app.logger.debug(f"Policy Name: {policy_name}")

        if policy_obj["reasons"]:

            for reason in policy_obj["reasons"]:

                app.logger.debug(f"Policy Failed")

                # Increment Prometheus Counters
                magtape_metrics_policies.labels(
                    count_type="total", policy=policy_name, ns=namespace
                ).inc()
                magtape_metrics_policies.labels(
                    count_type="fail", policy=policy_name, ns=namespace
                ).inc()

        else:

            app.logger.debug(f"Policy Passed")

            # Increment Prometheus Counters
            magtape_metrics_policies.labels(
                count_type="total", policy=policy_name, ns=namespace
            ).inc()
            magtape_metrics_policies.labels(
                count_type="pass", policy=policy_name, ns=namespace
            ).inc()

    return response_message


################################################################################
################################################################################
################################################################################


def get_namespace_slack(request_namespace, slack_webhook_secret):

    """Function to check for customer defined Slack Incoming Webhook URL in namespaced secret"""

    try:
        config.load_incluster_config()
    except config.ConfigException:
        try:
            config.load_kube_config()
        except config.ConfigException:
            raise Exception("Could not configure kubernetes python client")

    v1 = client.CoreV1Api()
    request_ns_secret = None

    try:

        request_ns_secret = v1.read_namespaced_secret(
            slack_webhook_secret, request_namespace
        )

    except ApiException as exception:

        if exception.reason == "Not Found":

            request_ns_secret = ""

            app.logger.debug(
                f'Slack Webhook Secret not detected for namespace "{request_namespace}": {exception}'
            )

            return None

        else:

            app.logger.info(
                f'Unable to query secrets in request namespace "{request_namespace}": {exception}'
            )

            return None

    if slack_webhook_secret_key in request_ns_secret.data:

        slack_webhook_url_customer = base64.b64decode(
            request_ns_secret.data[slack_webhook_secret_key]
        ).decode()

    else:

        app.logger.info(
            f'Key "{slack_webhook_secret_key}" not found in Slack Webhook Secret in request namespace "{request_namespace}"'
        )

        return None

    if slack_webhook_url_customer:

        app.logger.info(
            f'Slack Webhook Secret Detected for namespace "{request_namespace}"'
        )

        return slack_webhook_url_customer

    else:

        app.logger.info(
            f'No Slack Incoming Webhook URL Secret Detected for namespace "{request_namespace}'
        )

        return None


################################################################################
################################################################################
################################################################################


def send_k8s_event(
    magtape_pod_name, namespace, workload_type, workload, response_message
):

    """Function to create a k8s event in the target namespace upon policy failure"""

    # Load k8s client config
    try:
        config.load_incluster_config()
    except config.ConfigException:
        try:
            config.load_kube_config()
        except config.ConfigException:
            raise Exception("Could not configure kubernetes python client")

    # Create an instance of the API class
    api_instance = client.CoreV1Api()
    k8s_event_time = datetime.datetime.now(datetime.timezone.utc)

    # Build involved object for k8s event
    k8s_involved_object = client.V1ObjectReference(
        name=workload, kind=workload_type, namespace=namespace
    )

    # Build metadata for k8s event
    k8s_event_metadata = client.V1ObjectMeta(
        generate_name="magtape-policy-failure.",
        namespace=namespace,
        labels={"magtape-event": "policy-failure"},
    )

    # Build body for k8s event
    k8s_event_body = client.V1Event(
        action="MagTape Policy Failure",
        event_time=k8s_event_time,
        first_timestamp=k8s_event_time,
        involved_object=k8s_involved_object,
        last_timestamp=k8s_event_time,
        message=response_message,
        metadata=k8s_event_metadata,
        reason="MagTapePolicyFailure",
        type="Warning",
        reporting_component="magtape",
        reporting_instance=magtape_pod_name,
    )

    try:

        api_instance.create_namespaced_event(namespace, k8s_event_body)

    except ApiException as exception:

        app.logger.info(f"Exception when creating a namespace event: {exception}\n")


################################################################################
################################################################################
################################################################################


def slack_url_sub(slack_webhook_url):

    """Function to override the base domain for the Slack Incoming Webhook URL"""

    if "SLACK_WEBHOOK_URL_BASE" in os.environ:

        slack_webhook_url_base = os.environ["SLACK_WEBHOOK_URL_BASE"]

        slack_webhook_url = re.sub(
            r"(^https://)([a-z0-9\.]+)(.*)$",
            r"\1" + slack_webhook_url_base + r"\3",
            slack_webhook_url,
        )

        app.logger.info("Slack Webhook URL override detected")
        app.logger.debug(f"Slack Webhook URL after substitution: {slack_webhook_url}")

    return slack_webhook_url


################################################################################
################################################################################
################################################################################


def send_slack_alert(
    response_message,
    slack_target_type,
    slack_webhook_url,
    slack_user,
    slack_icon,
    cluster,
    namespace,
    workload,
    workload_type,
    request_user,
    customer_alert_sent,
    magtape_deny_level,
    is_allowed,
):

    """Function to format and send Slack alert for policy failures"""

    # Set Slack alert header and color appropriately for active/passive alerts
    alert_header = "MagTape | Policy Denial Detected"
    alert_color = "danger"

    if is_allowed:

        alert_header = "MagTape | Policy Failures Detected"
        alert_color = "warning"

    # Override Slack Webhook URL base domain if applicable
    slack_webhook_url = slack_url_sub(slack_webhook_url)

    slack_alert_data = {
        "username": f"{slack_user}",
        "icon_emoji": f"{slack_icon}",
        "attachments": [
            {
                "fallback": f'MagTape detected failures for {workload_type} "{workload}" in namespace "{namespace}" on cluster "{cluster}"',
                "color": f"{alert_color}",
                "pretext": f"{alert_header}",
                "text": response_message.replace(",", "\n"),
                "fields": [
                    {"title": "Cluster", "value": f"{cluster}", "short": "true"},
                    {"title": "Namespace", "value": f"{namespace}", "short": "true"},
                    {
                        "title": "MagTape Deny Level",
                        "value": f"{magtape_deny_level}",
                        "short": "true",
                    },
                    {
                        "title": "Workload",
                        "value": f"{workload_type.lower()}/{workload}",
                        "short": "false",
                    },
                    {"title": "User", "value": f"{request_user}", "short": "false"},
                    {
                        "title": "Customer Alert",
                        "value": f"{customer_alert_sent}",
                        "short": "true",
                    },
                ],
            }
        ],
    }

    app.logger.debug(
        f"Slack Alert Data: \n{json.dumps(slack_alert_data, indent=2, sort_keys=True)}"
    )

    try:

        slack_response = requests.post(
            slack_webhook_url,
            json=slack_alert_data,
            headers={"Content-Type": "application/json"},
            timeout=5,
        )

    except requests.exceptions.RequestException as exception:

        app.logger.info(
            f"Problem sending Slack Alert ({slack_target_type}): {exception}"
        )

    else:

        app.logger.info(
            f"Slack Alert ({slack_target_type}) was successful ({slack_response.status_code})"
        )
        app.logger.debug(f"Slack API Response ({slack_target_type}): {slack_response}")


################################################################################
################################################################################
################################################################################


def main():

    app.logger.info("MagTape Startup")

    app.run(
        host="0.0.0.0", port=5000, debug=False, threaded=True,
    )


################################################################################
################################################################################
################################################################################

if __name__ == "__main__":

    main()
