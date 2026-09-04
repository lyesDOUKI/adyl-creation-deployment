#!/bin/bash
set -e
CERTIFICATES_DIR="./certificates"
TRUSTSTORE="$CERTIFICATES_DIR/java-truststore.p12"

echo "=== Préparation du truststore Java ==="

docker run --rm \
  -v "$(pwd)/certificates:/certificates" \
  eclipse-temurin:25-jre \
  bash -c "
    cp /opt/java/openjdk/lib/security/cacerts /certificates/java-truststore.p12 &&
    keytool -importcert -trustcacerts -noprompt \
      -alias mkcert-root \
      -file /certificates/rootCA.pem \
      -keystore /certificates/java-truststore.p12 \
      -storepass changeit
  "

echo "Truststore Java créé : $TRUSTSTORE"