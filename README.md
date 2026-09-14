# 🔄 ToggleMaster — GitOps

Repositório de manifestos Kubernetes do ToggleMaster, monitorado
automaticamente pelo **ArgoCD** — Tech Challenge Fase 3.

## Como funciona

1. O pipeline de CI (repositório `togglemaster-fase2`) builda, testa e
   escaneia cada microsserviço.
2. Ao final, o CI publica a imagem no ECR com a tag `v1.0.0-<hash-do-commit>`.
3. O CI então **atualiza este repositório**, alterando a tag da imagem no
   `manifests/deployments.yaml`.
4. O **ArgoCD**, instalado no cluster EKS, detecta a mudança neste
   repositório automaticamente e sincroniza o cluster para o novo estado.

Isso elimina a necessidade de qualquer `kubectl apply` manual ou vindo do
pipeline de CI diretamente — o cluster nunca recebe credenciais externas de
CI/CD, apenas o ArgoCD (rodando dentro do próprio cluster) tem permissão de
aplicar mudanças.

## Estrutura

```
manifests/
├── namespace.yml
├── configmap.yaml
├── deployments.yaml
├── services.yml
├── ingress.yaml
└── hpa.yaml
```

**Nota:** `secrets.yaml` não é versionado aqui (nem em nenhum lugar público)
— é aplicado manualmente uma única vez fora do fluxo GitOps, já que soluções
robustas para Secrets em GitOps (Sealed Secrets, External Secrets Operator)
exigiriam infraestrutura adicional fora do escopo deste desafio.

## Application do ArgoCD

A Application que conecta o ArgoCD a este repositório está definida em
`argocd-application.yaml`, aplicada uma única vez no cluster:

```bash
kubectl apply -f argocd-application.yaml
```
