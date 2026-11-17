#!/usr/bin/env bash
# Gera trafego continuo no ToggleMaster (alimenta dashboard, traces e a regra de alerta).
# Uso: ./demo-load.sh [segundos=600]   (Ctrl+C para parar)
set -uo pipefail
DURATION="${1:-600}"
LB=$(kubectl get svc -n togglemaster -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].hostname}')
[ -n "$LB" ] || { echo "Nao achei o LoadBalancer do ingress (kubectl get svc -n togglemaster)"; exit 1; }
echo "Gerando carga em http://$LB por ${DURATION}s (Ctrl+C para parar)"
END=$((SECONDS + DURATION))
worker() {
  while [ $SECONDS -lt $END ]; do
    # evaluation -> flag-service -> auth (/validate) e evaluation -> targeting -> auth: trace distribuido completo
    curl -s -o /dev/null -m 5 "http://$LB/evaluate/evaluate?user_id=user-$RANDOM&flag_name=flag-$((RANDOM % 50))"
    # trafego direto no auth-service (chave invalida => 401, que NAO conta como erro 5xx)
    curl -s -o /dev/null -m 5 -H "Authorization: Bearer demo-key" "http://$LB/auth/validate"
    sleep 0.3
  done
}
for _ in 1 2 3 4; do worker & done
trap 'kill $(jobs -p) 2>/dev/null' EXIT INT
wait
