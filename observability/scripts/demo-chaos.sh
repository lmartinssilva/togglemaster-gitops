#!/usr/bin/env bash
# Liga/desliga a falha injetada no auth-service (/validate passa a responder 500).
# Uso: ./demo-chaos.sh on|off     (o self-healing "desliga" reiniciando o pod)
set -euo pipefail
MODE="${1:?uso: demo-chaos.sh on|off}"
case "$MODE" in on) EN=true ;; off) EN=false ;; *) echo "use on|off"; exit 1 ;; esac
KEY=$(cat ~/.togglemaster-master-key)
LB=$(kubectl get svc -n togglemaster -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].hostname}')
echo "chaos=$EN em http://$LB/auth/admin/chaos"
curl -s -m 10 -X POST "http://$LB/auth/admin/chaos" -H "Authorization: Bearer $KEY" \
  -H 'Content-Type: application/json' -d "{\"enabled\": $EN}"; echo
