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

from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
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
metrics.info('app_info', 'Application info', version='0.6')

# Set logging config
log = logging.getLogger("werkzeug")
log.disabled = True
magtape_log_level = os.environ['MAGTAPE_LOG_LEVEL']
app.logger.setLevel(magtape_log_level)

# Set Global variables
cluster = os.environ['MAGTAPE_CLUSTER_NAME']
magtape_namespace_name = os.environ['MAGTAPE_NAMESPACE_NAME']
magtape_pod_name = os.environ['MAGTAPE_POD_NAME']
magtape_tls_pair_secret_name = "magtape-tls"
magtape_tls_rootca_secret_name = "magtape-tls-ca"
magtape_byoc_annotation = "magtape-byoc"
magtape_service_name = "magtape-svc"
magtape_tls_path = "/tls"
magtape_tls_key = ""
magtape_tls_cert = ""
magtape_vwc_name = "magtape-vwc"

# Set Slack related variables
slack_enabled = os.environ['MAGTAPE_SLACK_ENABLED']
slack_passive = os.environ['MAGTAPE_SLACK_PASSIVE']
slack_webhook_url_default = os.environ['MAGTAPE_SLACK_WEBHOOK_URL_DEFAULT']
slack_webhook_annotation = os.environ['MAGTAPE_SLACK_ANNOTATION']
slack_user = os.environ['MAGTAPE_SLACK_USER']
slack_icon = os.environ['MAGTAPE_SLACK_ICON']

# Set K8s Events specific variables
k8s_events_enabled = os.environ['MAGTAPE_K8S_EVENTS_ENABLED']

# Set OPA Info
opa_base_url = os.environ['OPA_BASE_URL']
opa_k8s_path = os.environ['OPA_K8S_PATH']
opa_url = opa_base_url + opa_k8s_path

# Set Deny Level
magtape_deny_level = os.environ['MAGTAPE_DENY_LEVEL']

# Set Custom Prometheus Counters
# Request Metrics represent requests to the MagTape API
magtape_metrics_requests = Counter("magtape_requests", "Request Metrics for MagTape", ["count_type", "ns", "alert_sent"])
# Policy metrics represent individual policy evaluations
magtape_metrics_policies = Counter("magtape_policy", "Policy Metrics for MagTape", ["count_type", "policy", "ns"])

################################################################################
################################################################################
################################################################################

@app.route('/', methods=['POST'])

def webhook():

    """Function to call main logic and return k8s admission response"""

    request_info = request.json
    request_spec = copy.deepcopy(request_info)

    # Call Main Webhook function
    admissionReview = main(request_spec)

    # Return JSON formatted response object
    return jsonify(admissionReview)

################################################################################
################################################################################
################################################################################

@app.route('/healthz', methods=['GET'])

def healthz():

    """Function to return health info for app"""

    health_response = {
        "pod_name": magtape_pod_name,
        "date_time": str(datetime.datetime.now()),
        "health": "ok"
    }

    # Return JSON formatted response object
    return jsonify(health_response)

################################################################################
################################################################################
################################################################################

def main(request_spec):

    """main function"""

    # Zero out specific info per call
    allowed = True
    skip_alert = False
    response_message = ""
    alert_should_send = False
    alert_targets = []
    customer_alert_sent = False

    # Set Object specific info from request
    uid = request_spec['request']['uid']
    workload = request_spec['request']['object']['metadata']['name']
    workload_type = request_spec['request']['kind']['kind']
    namespace = request_spec['request']['namespace']
    request_user = request_spec['request']['userInfo']['username']

    app.logger.info("##################################################################")
    app.logger.info(f"Deny Level: {magtape_deny_level}")
    app.logger.info(f"Processing {workload_type}: {namespace}/{workload}")
    app.logger.info(f"Request User: {request_user}")
    app.logger.debug(f"Request Object: \n{json.dumps(request_spec, indent=2, sort_keys=True)}")

    if "ownerReferences" in request_spec['request']['object']['metadata'] and request_spec['request']['object']['metadata']['ownerReferences'][0]['kind'] == "ReplicaSet":
        
        # Set Owner Info
        k8s_object_owner_kind = request_spec['request']['object']['metadata']['ownerReferences'][0]['kind']
        k8s_object_owner_name = request_spec['request']['object']['metadata']['ownerReferences'][0]['name']
        
        # Set Skip for Alert
        skip_alert = True

    else:

        # Run MagTape Specific checks on requests objects
        response_message = build_response_message(request_spec, response_message, namespace)

        # Output policy decision
        for policy_response in response_message.split(", "):

            if policy_response:

                app.logger.info(policy_response)

            else:

                app.logger.info("[PASS] All checks")

    app.logger.debug(f"Skip Alert: {skip_alert}")

    # Set allowed value based on DENY_LEVEL and response_message content
    if magtape_deny_level == "OFF":

        app.logger.debug("Deny level detected: OFF")

        allowed = True

    elif magtape_deny_level == "LOW":

        DENY_LIST = ["[FAIL] HIGH"]

        app.logger.debug("Deny level detected: LOW")

        if any(denyword in response_message for denyword in DENY_LIST):

            app.logger.debug("Sev Fail level: HIGH")

            allowed = False
            alert_should_send = True

    elif magtape_deny_level == "MED":

        DENY_LIST = ["[FAIL] HIGH", "[FAIL] MED"]

        app.logger.debug("Deny level detected: MED")

        if any(denyword in response_message for denyword in DENY_LIST):

            app.logger.debug("Sev Fail level: HIGH/MED")

            allowed = False
            alert_should_send = True

    elif magtape_deny_level == "HIGH":

        DENY_LIST = ["[FAIL] HIGH", "[FAIL] MED", "[FAIL] LOW"]

        app.logger.debug("Deny level detected: HIGH")

        if any(denyword in response_message for denyword in DENY_LIST):

            app.logger.debug("Sev Fail level: HIGH/MED/LOW")

            allowed = False
            alert_should_send = True

    else:

        app.logger.debug("Deny level detected: NONE")

        allowed = False
        alert_should_send = True

    # Set optional message if allowed = false
    if allowed:

        admission_response = {
        "allowed": allowed
        }

    else:

        admission_response = {
            "uid": uid,
            "allowed": allowed,
            "status": {
                "message": response_message
            }
        }
    
    # Create K8s Event for target namespace if enabled
    if k8s_events_enabled == "TRUE":

        app.logger.info("K8s Event are enabled")

        if "FAIL" in response_message or alert_should_send:

            send_k8s_event(magtape_pod_name, namespace, workload_type, workload, response_message)

    else:

        app.logger.info("K8s Events are NOT enabled")

    # Send Slack message when failure is detected if enabled    
    if slack_enabled == "TRUE":

        app.logger.info("Slack alerts are enabled")

        if skip_alert:

            app.logger.info(f"Skipping alert for child object of previously validated parent \"{k8s_object_owner_kind}/{k8s_object_owner_name}\"")

        elif "FAIL" in response_message and slack_passive == "TRUE" or alert_should_send:

            # Add default Webhook URL to alert Targets
            alert_targets.append(slack_webhook_url_default)

            # Check Request namespace for custom Slack Webhook
            get_namespace_annotation(namespace, slack_webhook_annotation, alert_targets)

            # Set boolean to show whether a customer alert was sent
            if len(alert_targets) > 1:

                customer_alert_sent = True

            # Send alerts to all target Slack Webhooks
            for slack_target in alert_targets:

                send_slack_alert(response_message, slack_target, slack_user, slack_icon, cluster, namespace, workload, workload_type, request_user, customer_alert_sent, magtape_deny_level, allowed)

            # Increment Prometheus Counters
            if allowed:

                magtape_metrics_requests.labels(count_type = "allowed", ns = namespace, alert_sent = "true").inc()
                magtape_metrics_requests.labels(count_type = "total", ns = namespace, alert_sent = "true").inc()

            else:

                magtape_metrics_requests.labels(count_type = "denied", ns = namespace, alert_sent = "true").inc()
                magtape_metrics_requests.labels(count_type = "total", ns = namespace, alert_sent = "true").inc()

    else:

        app.logger.info(f"Slack alerts are NOT enabled")

        # Increment Prometheus Counters
        if allowed:

            magtape_metrics_requests.labels(count_type = "allowed", ns = namespace, alert_sent = "false").inc()
            magtape_metrics_requests.labels(count_type = "total", ns = namespace, alert_sent = "false").inc()

        else:

            magtape_metrics_requests.labels(count_type = "denied", ns = namespace, alert_sent = "false").inc()
            magtape_metrics_requests.labels(count_type = "total", ns = namespace, alert_sent = "false").inc()

    # Build Admission Response
    admissionReview = {
        "response": admission_response
    }
    
    app.logger.info("Sending Response to K8s API Server")
    app.logger.debug(f"Admission Review: \n{json.dumps(admissionReview, indent=2, sort_keys=True)}")

    return admissionReview

###############################################################################$
################################################################################
################################################################################

def check_for_byoc(namespace, secret, core_api):

    """Function to check for the "Bring Your Own Cert" annotation"""

    secret_name = secret.metadata.name
    secret_annotations = secret.metadata.annotations

    if secret_annotations and magtape_byoc_annotation in secret_annotations:

        app.logger.info(f"Detected the \"Bring Your Own Cert\" annotation for secret \"{secret_name}\"")

        try:

            secret = core_api.read_namespaced_secret(magtape_tls_rootca_secret_name, namespace)

        except ApiException as exception:

            if exception.status != 404:

                app.logger.info(f"An error occurred while trying to read secret \"{magtape_tls_rootca_secret_name}\" in the \"{namespace}\" namespace:\n{exception}\n")
                sys.exit()

            else:

                app.logger.info(f"\"Bring Your Own Cert\" annotation specified, but secret \"{magtape_tls_rootca_secret_name}\" was not found in the \"{namespace}\" namespace:\n{exception}\n")
                sys.exit()   

        if "rootca.pem" in secret.data and secret.data["rootca.pem"] != "":         

            return True

        else:

            app.logger.info(f"No key found or value is blank for \"rootca.pem\" in \"{secret.metadata.name}\" secret")
            sys.exit()

    else:

        return False

################################################################################
################################################################################
################################################################################

def build_k8s_csr(namespace, service_name, key):

    """Function to generate Kubernetes CSR"""

    # Store all dns names used for CN/SAN's
    dns_names = list()
    # K8s service intra namespace
    dns_names.insert(0, f"{service_name}")
    # K8s service inter namespace
    dns_names.insert(1, f"{service_name}.{namespace}")
    # K8s service full FQDN and Common Name
    dns_names.insert(2, f"{service_name}.{namespace}.svc")

    # Setup Certificate Signing Request
    csr = x509.CertificateSigningRequestBuilder()
    csr = csr.subject_name(
        # Provide Common Name
        x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, dns_names[2])])
    )

    csr = csr.add_extension(
        x509.SubjectAlternativeName([
            x509.DNSName(dns_names[0]),
            x509.DNSName(dns_names[1]),
            x509.DNSName(dns_names[2]),
        ]),
        critical=False,
    )

    # Sign the CSR with our private key.
    csr = csr.sign(key, hashes.SHA256(), default_backend())

    csr_pem = csr.public_bytes(serialization.Encoding.PEM)

    # Build Kubernetes CSR
    k8s_csr_meta = client.V1ObjectMeta(
        name=dns_names[1] + ".cert-request",
        namespace=namespace,
        labels={"app": "magtape"}
    )

    k8s_csr_spec = client.V1beta1CertificateSigningRequestSpec(
        groups=["system:authenticated"],
        usages=[
            "digital signature", 
            "key encipherment", 
            "server auth"
        ],
        request= base64.b64encode(csr_pem).decode('utf-8').rstrip(),
    )

    k8s_csr = client.V1beta1CertificateSigningRequest(
        api_version="certificates.k8s.io/v1beta1",
        kind="CertificateSigningRequest",
        metadata=k8s_csr_meta,
        spec=k8s_csr_spec,
    )

    app.logger.debug(f"CSR: {k8s_csr}\n")

    return k8s_csr

################################################################################
################################################################################
################################################################################

def submit_and_approve_k8s_csr(namespace, certificates_api, k8s_csr):

    """Function to submit or approve a Kubernetes CSR"""

    new_k8s_csr_name = k8s_csr.metadata.name

    # Read existing Kubernetes CSR
    try:

        certificates_api.read_certificate_signing_request(new_k8s_csr_name)

    except ApiException as exception:

        if exception.status != 404:

            app.logger.info(f"Problem reading existing certificate requests: {exception}\n")
            sys.exit()

        elif exception.status == 404:

            app.logger.info(f"Did not find existing certificate requests")
            app.logger.debug(f"Exception:\n{exception}\n")
            
    else:  

        try:

            certificates_api.delete_certificate_signing_request(new_k8s_csr_name)

        except ApiException as exception:

            if exception.status != 404:

                app.logger.info(f"Unable to delete existing certificate request \"{new_k8s_csr_name}\": {exception}\n")
                sys.exit()
            
            elif exception.status == 404:

                app.logger.info(f"Existing certificate request \"{new_k8s_csr_name}\" not found")
                app.logger.debug(f"Exception:\n{exception}\n")
        else:

            app.logger.info(f"Existing certificate request deleted")

    # Create K8s CSR resource
    try:

        app.logger.debug(k8s_csr)
        certificates_api.create_certificate_signing_request(k8s_csr)

    except ApiException as exception:

        app.logger.info(f"Unable to create certificate request \"{new_k8s_csr_name}\"\n")
        app.logger.debug(f"Exception:\n{exception}\n")

    # Read newly created K8s CSR resource
    try:
        
        new_k8s_csr_body = certificates_api.read_certificate_signing_request_status(new_k8s_csr_name)

    except ApiException as exception:

        app.logger.info(f"Unable to read certificate request status for \"{new_k8s_csr_name}\"\n")
        app.logger.debug(f"Exception:\n{exception}\n")

    new_k8s_csr_approval_conditions = client.V1beta1CertificateSigningRequestCondition(
        last_update_time=datetime.datetime.now(datetime.timezone.utc),
        message='This certificate was approved by MagTape',
        reason='MT-Approve',
        type='Approved'
    ) 

    # Update the CSR status
    new_k8s_csr_body.status.conditions = [new_k8s_csr_approval_conditions]

    # Patch the k8s CSR resource
    try:

        certificates_api.replace_certificate_signing_request_approval(new_k8s_csr_name, new_k8s_csr_body)

    except ApiException as exception:

        app.logger.info(f"Unable to update certificate request status for \"{new_k8s_csr_name}\": {exception}\n")

    # Retreive new 

    app.logger.info(f"Certificate signing request \"{new_k8s_csr_name}\" is approved")

    return new_k8s_csr_body

################################################################################
################################################################################
################################################################################

def get_tls_cert_from_request(namespace, secret_name, k8s_csr_name, certificates_api):

    """Function to retrieve tls certificate from approved Kubernetes CSR"""

    start_time = datetime.datetime.now()

    while (datetime.datetime.now() - start_time).seconds < 5:

        # Read existing Kubernetes CSR
        try:

            # Give a few seconds for the csr to be approved
            time.sleep(5)

            k8s_csr = certificates_api.read_certificate_signing_request(k8s_csr_name)

            app.logger.debug(k8s_csr)

        except ApiException as exception:

                app.logger.info(f"Problem reading certificate request \"{k8s_csr_name}\"\n")
                app.logger.debug(f"Exception:\n{exception}\n")

        tls_cert_b64 = k8s_csr.status.certificate
        conditions = k8s_csr.status.conditions or []
        

        if "Approved" in [condition.type for condition in conditions] and tls_cert_b64 != "":

                app.logger.info("Found approved certificate")
                
                break

        app.logger.info("Waiting for certificate approval")
        

    else:

        app.logger.info(f"Timed out reading certificate request \"{k8s_csr_name}\"\n")

    app.logger.debug(f"Cert RAW: {k8s_csr}")

    tls_cert = base64.b64decode(k8s_csr.status.certificate)

    app.logger.debug(f"Cert PEM: {tls_cert}")

    return tls_cert

################################################################################
################################################################################
################################################################################

def build_tls_pair(namespace, secret_name, service_name, certificates_api):

    """Function to generate signed tls certificate for admission webhook"""



    # Generate private key to use for CSR
    tls_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
        backend=default_backend()
    )

    tls_key_pem = tls_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.TraditionalOpenSSL,
        encryption_algorithm=serialization.NoEncryption(),
    )

    # Build K8s CSR
    k8s_csr = build_k8s_csr(namespace, service_name, tls_key)
    k8s_csr = submit_and_approve_k8s_csr(namespace, certificates_api, k8s_csr)
    tls_cert_pem = get_tls_cert_from_request(namespace, magtape_tls_pair_secret_name, k8s_csr.metadata.name, certificates_api)

    tls_pair = {
        "cert": tls_cert_pem,
        "key": tls_key_pem,
    }

    app.logger.debug(tls_pair)

    return tls_pair

    

################################################################################
################################################################################
################################################################################

def cert_expired(namespace, cert_data):

    """Function to check tls certificate return number of days until expiration"""

    current_datetime = datetime.datetime.now()
    tls_cert_decoded = base64.b64decode(cert_data["cert.pem"])
    tls_cert = x509.load_pem_x509_certificate(tls_cert_decoded, default_backend())
    expire_days = tls_cert.not_valid_after - current_datetime

    app.logger.info(f"Days until Cert Expiration: {expire_days.days}")

    return expire_days.days

################################################################################
################################################################################
################################################################################

def cert_should_update(namespace, cert_data, tls_byoc):

    """Function to check if tls certificate should be updated"""

    if cert_data["cert.pem"] == "" or cert_data["key.pem"] == "":

        if tls_byoc:

            app.logger.info(f"The \"Bring Your Own Cert\" annotation was used but one or more of the tls cert/key values are blank")
            sys.exit()

        return True

    days = cert_expired(namespace, cert_data)

    # Determine and report on cert expiry based on number of days from current date.
    # Cert should be valid for a year, but we update sooner to be safe
    if days <= 180:

        return True

    else:

        return False

################################################################################
################################################################################
################################################################################

def read_tls_pair(namespace, secret_name, tls_pair, core_api):

    """Function to read cert/key from k8s secret"""

    secret_exists = False

    # Try and read secret
    try:
        
        secret = core_api.read_namespaced_secret(secret_name, namespace)
        secret_exists = True

    except ApiException as exception:

        if exception.status != 404:

            app.logger.info(f"Unable to read secret \"{secret_name}\" in the \"{namespace}\" namespace\n")
            app.logger.debug(f"Exception:\n{exception}\n")

        else:

            app.logger.info(f"Did not find secret \"{secret_name}\" in the \"{namespace}\" namespace\n")
            app.logger.debug(f"Exception:\n{exception}\n")
        
        tls_pair = ""
        return tls_pair

    app.logger.debug(f"Secret data:\n {secret.data['cert.pem']}\n")

    tls_cert_pem = base64.b64decode(secret.data["cert.pem"])
    tls_key_pem = base64.b64decode(secret.data["key.pem"])

    tls_pair = {
        "cert": tls_cert_pem,
        "key": tls_key_pem,
    }


    return tls_pair, secret_exists

################################################################################
################################################################################
################################################################################

def write_tls_pair(namespace, secret_name, secret_exists, tls_pair, tls_byoc, core_api):

    """Function to write k8s secret for admission webhook to k8s secret and/or local files"""

    # If the secret isn't found, create it
    if secret_exists:

        app.logger.info(f"Using existing secret \"{secret_name}\" in namespace \"{namespace}\"")

    else:

        app.logger.info(f"Creating secret \"{secret_name}\" in namespace \"{namespace}\"")

        secret_metadata = client.V1ObjectMeta(
            name=secret_name,
            namespace=namespace,
            labels={"app": "magtape"}
        )

        secret_data = {
            "cert.pem":  base64.b64encode(tls_pair["cert"]).decode('utf-8').rstrip(),
            "key.pem":  base64.b64encode(tls_pair["key"]).decode('utf-8').rstrip(),
        }

        secret = client.V1Secret(
            metadata=secret_metadata,
            data=secret_data,
            type="tls"

        )

        app.logger.debug(f"New secret: {secret}")

        try:
            
            core_api.create_namespaced_secret(namespace, secret)

        except ApiException as exception:

            app.logger.info(f"Unable to create secret \"{secret_name}\" in the \"{namespace}\" namespace: {exception}\n")
            sys.exit()
        
        try:
            
            core_api.read_namespaced_secret(secret_name, namespace)

        except ApiException as exception:

            app.logger.info(f"Unable to read new secret \"{secret_name}\" in the \"{namespace}\" namespace: {exception}\n")
            sys.exit()

        app.logger.info(f"Created secret \"{secret_name}\" in namespace \"{namespace}\"")
    
    # If this is a BYOC pair, then skip the patch
    if not tls_byoc:

        #app.logger.info("Secret data is blank")

        secret = client.V1Secret()

        secret.data = {
            "cert.pem": base64.b64encode(tls_pair["cert"]).decode('utf-8').rstrip(),
            "key.pem": base64.b64encode(tls_pair["key"]).decode('utf-8').rstrip(),
        }

        try:

            core_api.patch_namespaced_secret(secret_name, namespace, secret)

        except ApiException as exception:

            app.logger.info(f"Unable to update secret \"{secret_name}\" in the \"{namespace}\" namespace: {exception}\n")
            sys.exit()

        app.logger.info(f"Patched new cert/key into existing secret")

        try:

            tls_pair, secret_exists = read_tls_pair(namespace, magtape_tls_pair_secret_name, tls_pair, core_api)

        except ApiException as exception:

            app.logger.info(f"Unable to read updated secret \"{secret_name}\" in the \"{namespace}\" namespace: {exception}\n")
            sys.exit()

        app.logger.info(f"Updated secret \"{secret_name}\" in namespace \"{namespace}\"")

    # Write cert and key to files for Flask app
    app.logger.info("Writing cert and key locally")
    app.logger.debug(f"TLS Pair: {tls_pair}")

    with open(f"{magtape_tls_path}/cert.pem", 'wb') as cert_file:
        cert_file.write(tls_pair["cert"])

    with open(f"{magtape_tls_path}/key.pem", 'wb') as key_file:
        key_file.write(tls_pair["key"])

################################################################################
################################################################################
################################################################################

def init_tls_pair(namespace):

    """Function to load or create tls for admission webhook"""

    tls_pair = ""

    app.logger.info("Starting TLS init process")

    # Check if custom secret was specified in ENV vars
    magtape_tls_secret = os.getenv("MAGTAPE_TLS_SECRET", magtape_tls_pair_secret_name)

    if magtape_tls_secret != magtape_tls_pair_secret_name:

        app.logger.debug("Magtape TLS Secret specified")

    try:

        config.load_incluster_config()

    except Exception as exception:

        app.logger.info(f"Exception loading incluster configuration: {exception}")

        try:
            app.logger.info("Loading local kubeconfig")
            config.load_kube_config()

        except Exception as exception:

            app.logger.info(f"Exception loading local kubeconfig: {exception}")
            sys.exit()

    configuration = client.Configuration()
    core_api = client.CoreV1Api(client.ApiClient(configuration))
    certificates_api = client.CertificatesV1beta1Api(client.ApiClient(configuration))

    try:
    
        secret = core_api.read_namespaced_secret(magtape_tls_pair_secret_name, namespace)

        cert_data = secret.data

    except ApiException as exception:

        if exception.status != 404:

            app.logger.info(f"Unable to read secret in the \"{namespace}\" namespace: {exception}\n")
            sys.exit()

        elif exception.status == 404:

            app.logger.info(f"Did not find secret \"{magtape_tls_pair_secret_name}\" in the \"{namespace}\" namespace")
            app.logger.debug(f"Exception:\n{exception}\n")
            
            cert_data = ""

    tls_byoc = check_for_byoc(namespace, secret, core_api)

    # Read existing secret
    tls_pair, secret_exists = read_tls_pair(namespace, magtape_tls_pair_secret_name, tls_pair, core_api)

    if secret_exists:

        app.logger.info("Existing TLS cert and key found")

    # Check if cert should be updated
    if cert_should_update(namespace, cert_data, tls_byoc):

        if tls_byoc:

            app.logger.info(f"WARN - Certificate used for Admission Webhook is past threshhold for normal rotation. Not rotating because this cert isn't managed by the K8s CA")

        else:

            app.logger.info(f"Generating new cert/key pair for TLS")

            # Generate TLS Pair
            tls_pair = build_tls_pair(namespace, magtape_tls_pair_secret_name, magtape_service_name, certificates_api)
            # We set this to Falso so new secret is written

    # Handle cert creation or update
    write_tls_pair(namespace, magtape_tls_secret, secret_exists, tls_pair, tls_byoc, core_api)

################################################################################
################################################################################
################################################################################

def get_rootca(namespace):

    """Function to get root ca used for securing admission webhook"""

################################################################################
################################################################################
################################################################################

def verify_vwc_cert_bundle(namespace):

    """Function to create or update the k8s validating webhook configuration"""

################################################################################
################################################################################
################################################################################

def read_vwc(admission_api):

    """Function to read k8s validating webhook configuration"""

    try:
            
        vwc = admission_api.read_validating_webhook_configuration(magtape_vwc_name)

    except ApiException as exception:

        if exception.status != 404:

            app.logger.info(f"Unable to read VWC \"{magtape_vwc_name}\": {exception}\n")
            sys.exit()

        elif exception.status == 400:

            app.logger.info(f"Did not find existing VWC \"{magtape_vwc_name}\"")
            app.logger.debug(f"Exception:\n{exception}\n")
            
            vwc = ""
            return vwc

    app.logger.info(f"Existing VWC \"{magtape_vwc_name}\" found")

    return vwc

################################################################################
################################################################################
################################################################################

def write_vwc(namespace, ca_secret_name, admission_api):

    """Function to create or update the k8s validating webhook configuration"""

    verified = verify_vwc_cert_bundle(magtape_vwc_name, admission_api)

################################################################################
################################################################################
################################################################################

def init_vwc(namespace):

    """Function to handle the k8s validating webhook configuration"""

    """
    - check for existing VWC
        - If it exists
            - read CA
                - if self-signed CA read from magtape-tls-ca secret
                - else read from in-cluster kubeconfig
            - Compare Found CA to CA in existing VWC
                - if different
                    - patch VWC
                - else
                    - do nothing
        If it doesn't exist
            - Create it
                if "self-signed-ca" is true
                    - read CA
                        - if self-signed CA read from magtape-tls-ca secret
                        - else read from in-cluster kubeconfig
                    - Build VWC
                    - Write VWC
            
    """

    try:

        config.load_incluster_config()

    except Exception as exception:

        app.logger.info(f"Exception loading incluster configuration: {exception}")

        try:
            app.logger.info("Loading local kubeconfig")
            config.load_kube_config()

        except Exception as exception:

            app.logger.info(f"Exception loading local kubeconfig: {exception}")
            sys.exit()

    configuration = client.Configuration()
    admission_api = client.AdmissionregistrationV1beta1Api(client.ApiClient(configuration))

    vwc = read_vwc(admission_api)
    write_vwc(namespace, magtape_tls_rootca_secret_name, admission_api)

################################################################################
################################################################################
################################################################################

def build_response_message(object_spec, response_message, namespace):

    """Function to build the response message used to inform users of policy decisions"""

    try:
    
        opa_response = requests.post(

            opa_url, json=object_spec,
            headers = {'Content-Type': 'application/json'},
            timeout = 5

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

        app.logger.info(f"Request to OPA returned an error {opa_response.status_code}, the response is:\n{opa_response.text}")

        response_message = "[FAIL] HIGH - Call to OPA was unsuccessful. Please contact your cluster administrator"

        return response_message

    # Load OPA request results as JSON
    opa_response_json = json.loads(opa_response.text)['decisions']

    app.logger.debug(f"OPA JSON:\n{opa_response_json}")

    # Build response message from "msg" component of each object in the OPA response
    messages = []

    # Note this entire statement can likely be broken down into a simpler chained 
    # generator/list comprehension statement.....I tried, but couldn't get it to work
    # Something similar to:
    # opa_response_msg = ", ".join(reason['msg'] for reason in decision['reasons'] for decision in opa_response_json)
    for decision in opa_response_json:

        for reason in decision['reasons']:

            messages.append(reason['msg'])

    # Sort messages for consistent output
    messages.sort()

    opa_response_msg = ", ".join(messages)

    # Cleanup artifacts from OPA response before sending to K8s API
    response_message = re.sub(r"^\[\'|\'\]$|\'(\, )\'", r"\1", opa_response_msg)

    app.logger.debug(f"response_message:\n{response_message}")

    # Increment Prometheus counter for each policy object in the OPA response
    for policy_obj in opa_response_json:

        policy_name = re.sub("policy-", "", policy_obj['policy']).replace("_", "-")

        app.logger.debug(f"Policy Object: {policy_obj}")
        app.logger.debug(f"Policy Name: {policy_name}")

        if policy_obj['reasons']:
        
            for reason in policy_obj['reasons']:

                    app.logger.debug(f"Policy Failed")

                    # Increment Prometheus Counters
                    magtape_metrics_policies.labels(count_type = "total", policy = policy_name, ns = namespace).inc()
                    magtape_metrics_policies.labels(count_type = "fail", policy = policy_name, ns = namespace).inc()

        else:

            app.logger.debug(f"Policy Passed")

            # Increment Prometheus Counters
            magtape_metrics_policies.labels(count_type = "total", policy = policy_name, ns = namespace).inc()
            magtape_metrics_policies.labels(count_type = "pass", policy = policy_name, ns = namespace).inc()

    return response_message

################################################################################
################################################################################
################################################################################

def get_namespace_annotation(request_namespace, slack_webhook_annotation, alert_targets):

    """Function to check for customer defined Slack Incoming Webhook URL in namespace annotation"""

    config.load_incluster_config()

    v1 = client.CoreV1Api()

    try:
        
        request_ns_annotations = v1.read_namespace(request_namespace).metadata.annotations

        app.logger.debug(f"Request Namespace Annotations: {request_ns_annotations}")

    except ApiException as exception:

        app.logger.info(f"Unable to query K8s namespace for Slack Webhook URL annotation: {exception}\n")

    if request_ns_annotations and slack_webhook_annotation in request_ns_annotations:

        slack_webhook_url_customer = request_ns_annotations[slack_webhook_annotation]

        if slack_webhook_url_customer:

            app.logger.info(f"Slack Webhook Annotation Detected for namespace \"{request_namespace}\"")
            app.logger.debug(f"Slack Webhook Annotation Value: {slack_webhook_url_customer}")

            alert_targets.append(slack_webhook_url_customer)
            
        else:

            app.logger.info(f"No Slack Incoming Webhook URL Annotation Detected, using default")
            app.logger.debug(f"Default Slack Webhook URL: {slack_webhook_url_default}")

################################################################################
################################################################################
################################################################################

def send_k8s_event(magtape_pod_name, namespace, workload_type, workload, response_message):

    """Function to create a k8s event in the target namespace upon policy failure"""

    # Load k8s client config
    config.load_incluster_config()

    # Create an instance of the API class
    api_instance = client.CoreV1Api()
    k8s_event_time = datetime.datetime.now(datetime.timezone.utc)

    # Build involved object for k8s event
    k8s_involved_object = client.V1ObjectReference(
        name=workload, 
        kind=workload_type, 
        namespace=namespace
    )

    # Build metadata for k8s event
    k8s_event_metadata = client.V1ObjectMeta(
        generate_name="magtape-policy-failure.",
        namespace=namespace,
        labels={"magtape-event": "policy-failure"}
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
        reporting_instance=magtape_pod_name
    )

    try: 

        api_response = api_instance.create_namespaced_event(namespace, k8s_event_body)

    except ApiException as exception:

        app.logger.info(f"Exception when creating a namespace event: {exception}\n")

################################################################################
################################################################################
################################################################################

def slack_url_sub(slack_webhook_url):

    """Function to override the base domain for the Slack Incoming Webhook URL"""

    if "SLACK_WEBHOOK_URL_BASE" in os.environ:

        slack_webhook_url_base = os.environ['SLACK_WEBHOOK_URL_BASE']

        slack_webhook_url = re.sub(r'(^https://)([a-z0-9\.]+)(.*)$', r"\1" + slack_webhook_url_base + r"\3", slack_webhook_url)

        app.logger.info("Slack Webhook URL override detected")
        app.logger.debug(f"Slack Webhook URL after substitution: {slack_webhook_url}")

    return slack_webhook_url

################################################################################
################################################################################
################################################################################

def send_slack_alert(response_message,slack_webhook_url, slack_user, slack_icon, cluster, namespace, workload, workload_type, request_user, customer_alert_sent, magtape_deny_level, allowed):

    """Function to format and send Slack alert for policy failures"""

    # Set Slack alert header and color appropriately for active/passive alerts
    alert_header = "MagTape | Policy Denial Detected"
    alert_color = "danger"

    if allowed:

        alert_header = "MagTape | Policy Failures Detected"
        alert_color = "warning"

    # Override Slack Webhook URL base domain if applicable
    slack_webhook_url = slack_url_sub(slack_webhook_url)
    
    slack_alert_data = {
      "username": f"{slack_user}",
      "icon_emoji": f"{slack_icon}",
      "attachments": [{
            "fallback": f"MagTape detected failures for {workload_type} \"{workload}\" in namespace \"{namespace}\" on cluster \"{cluster}\"",
            "color": f"{alert_color}",
            "pretext": f"{alert_header}",
            "text": response_message.replace(",", "\n"),
            "fields": [
                {
                    "title": "Cluster",
                    "value": f"{cluster}",
                    "short": "true"
                },
				{
                    "title": "Namespace",
                    "value": f"{namespace}",
                    "short": "true"
                },
                {
                    "title": "MagTape Deny Level",
                    "value": f"{magtape_deny_level}",
                    "short": "true"
                },
				{
                    "title": "Workload",
                    "value": f"{workload_type.lower()}/{workload}",
                    "short": "false"
                },
                {
                    "title": "User",
                    "value": f"{request_user}",
                    "short": "false"
                },
                {
                    "title": "Customer Alert",
                    "value": f"{customer_alert_sent}",
                    "short": "true"
                }
            ]
        }]
    }

    app.logger.debug(f"Slack Alert Data: \n{json.dumps(slack_alert_data, indent=2, sort_keys=True)}")

    try: 
        slack_response = requests.post(

            slack_webhook_url,
            json = slack_alert_data,
            headers = {'Content-Type': 'application/json'},
            timeout = 5

        )

        app.logger.info(f"Slack Alert was successful ({slack_response.status_code})")
        app.logger.debug(f"Slack API Response: {slack_response}")

    except requests.exceptions.RequestException as exception:

        app.logger.info(f"Problem sending Alert to Slack: {exception}")

################################################################################
################################################################################
################################################################################

if __name__ == "__main__":

    app.logger.info("MagTape Startup")

    init_tls_pair(magtape_namespace_name)
    
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True, ssl_context=(f"{magtape_tls_path}/cert.pem", f"{magtape_tls_path}/key.pem"))
