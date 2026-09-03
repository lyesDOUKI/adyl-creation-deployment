#!/bin/bash
#
# deploy.sh — build et déploiement de la stack
#
# Usage:
#   ./deploy.sh [<tag-api>]
#
# Exemples:
#   ./deploy.sh v1.2.0     # tag purement informatif (affiché en fin de script)
#   ./deploy.sh            # équivalent à 'main'

set -euo pipefail

# ── Couleurs (désactivées si sortie non-tty) ────────────────────────────────
if [ -t 1 ]; then
  BOLD='\033[1m'; GREEN='\033[0;32m'; RED='\033[0;31m'; DIM='\033[2m'; RESET='\033[0m'
else
  BOLD=''; GREEN=''; RED=''; DIM=''; RESET=''
fi

readonly TAG="${1:-main}"
readonly TOTAL_STEPS=3
STEP=0
CURRENT_STEP_NAME=""

log_step() {
  STEP=$((STEP + 1))
  CURRENT_STEP_NAME="$1"
  echo ""
  echo -e "${BOLD}▶ [${STEP}/${TOTAL_STEPS}] ${CURRENT_STEP_NAME}${RESET}"
}

log_info() {
  echo -e "${DIM}  · $1${RESET}"
}

on_error() {
  echo ""
  echo -e "${RED}❌ Échec à l'étape [${STEP}/${TOTAL_STEPS}] : ${CURRENT_STEP_NAME}${RESET}"
  echo -e "${RED}   Voir les logs ci-dessus pour le détail de l'erreur.${RESET}"
  exit 1
}
trap on_error ERR

# ── Vérifications préalables ────────────────────────────────────────────────
if [ ! -f ".env" ]; then
  echo -e "${RED}❌ Fichier .env introuvable. Copie .env.example en .env avant de continuer.${RESET}"
  exit 1
fi

echo -e "${BOLD}🚀 Déploiement de la stack Adyl Creation (tag: ${TAG})${RESET}"

# ── Étape 1 : truststore Java ───────────────────────────────────────────────
log_step "Préparation du truststore Java"
./scripts/setup-java-truststore.sh
log_info "truststore prêt"

# ── Étape 2 : build des images locales ──────────────────────────────────────
log_step "Construction des images locales (Keycloak optimisé)"
docker compose build --parallel
log_info "images construites"

# ── Étape 3 : déploiement ───────────────────────────────────────────────────
log_step "Déploiement de la stack"
docker compose pull
docker compose up -d --force-recreate
log_info "conteneurs relancés"

# ── Résumé ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}✅ Stack déployée avec succès (tag: ${TAG})${RESET}"
echo ""
docker compose ps