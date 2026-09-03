ARG KEYCLOAK_VERSION=26.0.0
FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}

# Déclare les options de build obligatoires pour qu'elles soient figées dans l'image
ENV KC_DB=postgres
ENV KC_HEALTH_ENABLED=true

# Étape de Build avec les options intégrées
RUN /opt/keycloak/bin/kc.sh build

# Commande de démarrage optimisée
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start", "--optimized"]