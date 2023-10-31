#!/bin/bash
# -*- mode: sh -*-
# © Copyright IBM Corporation 2021
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

KEY=server.key
CERT=server.crt
KEYDB=server.kdb
KEYP12=server.p12
KEY_APP=application.key
CERT_APP=application.crt
KEYDB_APP=application.kdb
KEYP12_APP=application.p12
PASSWORD=password

# Create a private key and certificate in PEM format, for the server to use
echo "#### Create a private key and certificate in PEM format, for the server to use"
openssl req \
       -newkey rsa:2048 -nodes -keyout ${KEY} \
       -subj "/CN=queuemanager/OU=mq" \
       -x509 -days 3650 -out ${CERT}


# Create a private key and certificate in PEM format, for the application to use
echo "#### Create a private key and certificate in PEM format, for the application to use"
openssl req \
       -newkey rsa:2048 -nodes -keyout ${KEY_APP} \
       -subj "/OU=team1/CN=service1" \
       -x509 -days 3650 -out ${CERT_APP}


# Add the key and certificate to a kdb key store, for the server to use
echo "#### Creating kdb key store, for the server to use"
/opt/mqm/bin/runmqakm -keydb -create -db ${KEYDB} -pw ${PASSWORD} -type cms -expire 1000 -stash
echo "#### Adding public cert to kdb key store, for the server to use"
/opt/mqm/bin/runmqakm -cert -add -db ${KEYDB} -stashed -trust enable -file ${CERT_APP} -label "OU=team1,CN=service1"
echo "#### Adding private key to kdb key store, for the server to use"
openssl pkcs12 -export -out ${KEYP12} -inkey ${KEY} -in ${CERT} -passout pass:password -name default
/opt/mqm/bin/runmqakm -cert -import -file ${KEYP12} -pw password -type pkcs12 -target ${KEYDB} -target_stashed -target_type cms
keytool -importkeystore -srckeystore application.p12 -destkeystore server.jks -srcstoretype pkcs12 -alias "OU=team1,CN=service1" -storepass password -srcstorepass password

# Add the key and certificate to a kdb key store, for the application to use
echo "#### Add the key and certificate to a kdb key store, for the application to use"
/opt/mqm/bin/runmqakm -keydb -create -db ${KEYDB_APP} -pw ${PASSWORD} -type cms -expire 1000 -stash
echo "#### Adding public cert to kdb key store, for the application to use"
/opt/mqm/bin/runmqakm -cert -add -db ${KEYDB_APP} -stashed -trust enable -file ${CERT} -label default
echo "#### Adding private key to kdb key store, for the server to use"
openssl pkcs12 -export -out ${KEYP12_APP} -inkey ${KEY_APP} -in ${CERT_APP} -passout pass:password -name "OU=team1,CN=service1"
/opt/mqm/bin/runmqakm -cert -import -file ${KEYP12_APP} -pw password -type pkcs12 -target ${KEYDB_APP} -target_stashed -target_type cms

keytool -import -trustcacerts -alias default -file ${CERT} -keystore application.jks -storepass password  
