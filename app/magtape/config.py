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

from os import environ as env
import multiprocessing

APP_PORT = int(env.get("APP_PORT", 5000))
APP_DEBUG = int(env.get("APP_DEBUG", 1))
magtape_tls_path = "/tls"

# Gunicorn config
bind = ":" + str(APP_PORT)
workers = 2
threads = 2
certfile = magtape_tls_path + "/cert.pem"
keyfile = magtape_tls_path + "/key.pem"
