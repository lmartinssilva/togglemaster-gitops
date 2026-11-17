#!/usr/bin/env bash
# Cria no cluster os Secrets da stack de observabilidade a partir de um arquivo
# LOCAL (fora do Git). Idempotente: pode rodar de novo a qualquer momento.
# Uso: ./create-secrets.sh [~/observability-keys.env]
set -euo pipefail
ENV_FILE="${1:-$HOME/observability-keys.env}"
[ -f "$ENV_FILE" ] || { echo "Arquivo $ENV_FILE nao encontrado (veja observability-keys.env.example)"; exit 1; }

set -a; source "$ENV_FILE"; set +a
: "${DD_API_KEY:?DD_API_KEY vazio}" "${DD_SITE:?DD_SITE vazio}"
: "${PAGERDUTY_INTEGRATION_KEY:?PAGERDUTY_INTEGRATION_KEY vazio}" "${SLACK_WEBHOOK_URL:?SLACK_WEBHOOK_URL vazio}"

if [ -z "${REMEDIATOR_TOKEN:-}" ]; then
  REMEDIATOR_TOKEN=$(openssl rand -hex 24); echo "REMEDIATOR_TOKEN='$REMEDIATOR_TOKEN'" >> "$ENV_FILE"
fi
if [ -z "${GRAFANA_ADMIN_PASSWORD:-}" ]; then
  GRAFANA_ADMIN_PASSWORD=$(openssl rand -hex 12); echo "GRAFANA_ADMIN_PASSWORD='$GRAFANA_ADMIN_PASSWORD'" >> "$ENV_FILE"
fi

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
mk() { kubectl create secret generic "$@" -n monitoring --dry-run=client -o yaml | kubectl apply -f -; }
mk grafana-admin --from-literal=admin-user=admin --from-literal=admin-password="$GRAFANA_ADMIN_PASSWORD"
mk datadog-credentials --from-literal=DD_API_KEY="$DD_API_KEY" --from-literal=DD_SITE="$DD_SITE"
mk grafana-alert-secrets \
  --from-literal=PAGERDUTY_INTEGRATION_KEY="$PAGERDUTY_INTEGRATION_KEY" \
  --from-literal=SLACK_WEBHOOK_URL="$SLACK_WEBHOOK_URL" \
  --from-literal=REMEDIATOR_TOKEN="$REMEDIATOR_TOKEN"

echo "Secrets criados em 'monitoring'. Login do Grafana: admin / $GRAFANA_ADMIN_PASSWORD"
