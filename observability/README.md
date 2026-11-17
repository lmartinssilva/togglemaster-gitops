# Fase 4 - Observabilidade e resposta ativa (ToggleMaster)

## Arquitetura
```
apps (OTLP/HTTP) -> otel-gateway (Deployment) -+-> Prometheus (metricas via remote write, inclui RED derivado dos traces)
pods (logs)      -> otel-agent (DaemonSet) ----+-> Loki (logs, OTLP nativo)
                                               +-> Datadog (traces/APM + Service Map)
Grafana (dashboard + alerting) --alerta--> PagerDuty (incidente) + Slack (ChatOps) + self-healer (rollout restart)
```
Tudo e instalado por GitOps (ArgoCD): `argocd-observability.yaml` -> `observability/apps/*` (Helm) e `observability/extras` (dashboard, alerta, self-healer).

## Ordem de subida
1. `~/observability-keys.env` preenchido (Datadog, PagerDuty, Slack) e `observability/scripts/create-secrets.sh`
2. `kubectl apply -f argocd-observability.yaml`
3. Aguardar apps `Healthy` no ArgoCD (`kubectl get applications -n argocd`)
4. `kubectl -n monitoring port-forward svc/kps-grafana 3000:80` -> http://localhost:3000 (admin / senha do create-secrets)

## Demo da falha (roteiro)
1. `observability/scripts/demo-load.sh 900` (terminal 1): trafego continuo
2. Grafana: dashboard "ToggleMaster - Observabilidade"; Datadog: Service Map + um trace de /evaluate
3. `observability/scripts/demo-chaos.sh on`: auth-service passa a responder 500
4. ~2 min: o alerta dispara -> incidente no PagerDuty + mensagem no Slack + self-healer reinicia o auth-service
5. `kubectl logs -n monitoring deploy/self-healer` (log do self-healing) e `kubectl get pods -n togglemaster -w`
6. Taxa de erros volta a zero, o alerta resolve, o incidente e resolvido sozinho.
