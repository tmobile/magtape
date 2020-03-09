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
from kubernetes import client, config
from kubernetes.client.rest import ApiException
from logging.handlers import MemoryHandler
import base64
import datetime
import logging
import os
import sys
import time

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

            app.logger.info(f"Did not find existing certificate requests\n")
            
    else:  

        try:

            certificates_api.delete_certificate_signing_request(new_k8s_csr_name)

        except ApiException as exception:

            if exception.status != 404:

                app.logger.info(f"Unable to delete existing certificate request \"{new_k8s_csr_name}\": {exception}\n")
                sys.exit()
            
            elif exception.status == 404:

                app.logger.info(f"Existing certificate request \"{new_k8s_csr_name}\" not found")
        else:

            app.logger.info(f"Existing certificate request deleted")

    # Create K8s CSR resource
    try:

        app.logger.debug(k8s_csr)
        certificates_api.create_certificate_signing_request(k8s_csr)

    except ApiException as exception:

        app.logger.info(f"Unable to create certificate request \"{new_k8s_csr_name}\": {exception}\n")

    # Read newly created K8s CSR resource
    try:
        
        new_k8s_csr_body = certificates_api.read_certificate_signing_request_status(new_k8s_csr_name)

    except ApiException as exception:

        app.logger.info(f"Unable to read certificate request status for \"{new_k8s_csr_name}\": {exception}\n")

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
            print("Before sleep")
            time.sleep(5)
            print("After sleep")
            k8s_csr = certificates_api.read_certificate_signing_request(k8s_csr_name)

            app.logger.debug(k8s_csr)

        except ApiException as exception:

                app.logger.info(f"Problem reading certificate request \"{k8s_csr_name}\": {exception}\n")

        tls_cert_b64 = k8s_csr.status.certificate
        conditions = k8s_csr.status.conditions or []
        

        if "Approved" in [condition.type for condition in conditions] and tls_cert_b64 != "":

                app.logger.info("Found approved certificate")
                
                break

        app.logger.info("Waiting for certificate approval")
        

    else:

        app.logger.info(f"Timed out reading certificate request \"{k8s_csr_name}\"\n")

    app.logger.info(f"Cert RAW: {k8s_csr}")

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

def cert_should_update(namespace, cert_data):

    """Function to check if tls certificate should be updated"""

    if cert_data == "":

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

    # Try and read secret
    try:
        
        secret = core_api.read_namespaced_secret(secret_name, namespace)

    except ApiException as exception:

        app.logger.info(f"Unable to read secret \"{secret_name}\" in the \"{namespace}\" namespace: {exception}\n")

    app.logger.debug(f"Secret data:\n {secret.data['cert.pem']}\n")

    tls_cert_pem = base64.b64decode(secret.data["cert.pem"])
    tls_key_pem = base64.b64decode(secret.data["key.pem"])

    tls_pair = {
        "cert": tls_cert_pem,
        "key": tls_key_pem,
    }

    return tls_pair

################################################################################
################################################################################
################################################################################

def write_tls_pair(namespace, secret_name, tls_pair, core_api):

    """Function to write k8s secret for admission webhook to k8s secret and/or local files"""

    app.logger.info("Checking for existing secret")

    existing_secret = ""

    # Try and read secret
    try:
        
        existing_secret = core_api.read_namespaced_secret(secret_name, namespace)

    except ApiException as exception:

        app.logger.info(f"Unable to read secret \"{secret_name}\" in the \"{namespace}\" namespace: {exception}\n")

    # If the secret isn't found, create it
    if existing_secret:

        app.logger.info(f"Found existing secret \"{secret_name}\" in namespace \"{namespace}\"")

    else:

        app.logger.info(f"Existing secret \"{secret_name}\" not found in namespace \"{namespace}\"")

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

        app.logger.info(f"New secret: {secret}")

        try:
            
            core_api.create_namespaced_secret(namespace, secret)

        except ApiException as exception:

            app.logger.info(f"Unable to create secret \"{secret_name}\" in the \"{namespace}\" namespace: {exception}\n")
            sys.exit()
        
        try:
            
            new_secret = core_api.read_namespaced_secret(secret_name, namespace)

        except ApiException as exception:

            app.logger.info(f"Unable to read new secret \"{secret_name}\" in the \"{namespace}\" namespace: {exception}\n")
            sys.exit()

        app.logger.info(f"Created secret \"{secret_name}\" in namespace \"{namespace}\"")

    secret = client.V1Secret()

    if secret.data == "":

        app.logger.info("Secret data is blank")

        secret.data = {
            "cert.pem": tls_pair["cert"],
            "key.pem": tls_pair["key"]
        }

        core_api.patch_namespaced_secret(secret_name, namespace, secret)

        new_secret = core_api.read_namespaced_secret(secret_name, namespace)

        if not new_secret:

            app.logger.info(f"Error updating secret \"{secret_name}\" in namespace \"{namespace}\"")

        else:

            app.logger.info(f"Updated secret \"{secret_name}\" in namespace \"{namespace}\"")

    # Write cert and key to files for Flask app

    app.logger.info("Writing cert and key locally")

    os.mkdir(magtape_tls_path)

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
            
            cert_data = ""

    # Read existing secret
    tls_pair = read_tls_pair(namespace, magtape_tls_pair_secret_name, tls_pair, core_api)

    # Check if cert should be updated
    if cert_should_update(namespace, cert_data):

        app.logger.info(f"Generating new cert/key pair for TLS")

        # Generate TLS Pair
        tls_pair = build_tls_pair(namespace, magtape_tls_pair_secret_name, magtape_service_name, certificates_api)

    # Handle cert creation or update
    write_tls_pair(namespace, magtape_tls_secret, tls_pair, core_api)