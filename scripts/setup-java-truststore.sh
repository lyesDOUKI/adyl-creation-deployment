#!/bin/bash

set -e

CERTIFICATES_DIR="./certificates"
TRUSTSTORE="$CERTIFICATES_DIR/java-truststore.p12"
ROOT_CA="$CERTIFICATES_DIR/rootCA.pem"

echo "=== Préparation du truststore Java ==="

rm -f "$TRUSTSTORE"

docker run --rm \
  -v "$(pwd)/certificates:/certificates" \
  eclipse-temurin:25-jre \
  keytool -importkeystore \
    -srckeystore /opt/java/openjdk/lib/security/cacerts \
    -srcstorepass changeit \
    -destkeystore /certificates/java-truststore.p12 \
    -deststorepass changeit \
    -deststoretype PKCS12

docker run --rm \
  -v "$(pwd)/certificates:/certificates" \
  eclipse-temurin:25-jre \
  keytool -importcert \
    -trustcacerts \
    -noprompt \
    -alias mkcert-root \
    -file /certificates/rootCA.pem \
    -keystore /certificates/java-truststore.p12 \
    -storepass changeit

echo "Truststore Java créé : $TRUSTSTORE"