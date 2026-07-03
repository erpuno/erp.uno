#!/bin/bash
# deploy-erp-uno.sh - GitOps deployment via ArgoCD

set -eu

NAMESPACE="erp-uno"
DOMAIN="${DOMAIN:-erp.uno}"
ENVIRONMENT="${ENVIRONMENT:-production}"

echo "[*] Deploying ERP.uno to $NAMESPACE ($ENVIRONMENT)"

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply Helm chart
helm upgrade --install erp-uno ./helm \
  --namespace $NAMESPACE \
  --values ./helm/values.yaml \
  --set global.domain=$DOMAIN \
  --set global.environment=$ENVIRONMENT \
  --set global.registry="registry.erp.uno" \
  --wait \
  --timeout 5m

echo "[✓] ERP.uno deployment complete"

# Wait for key services
echo "[*] Waiting for critical services..."
kubectl wait --for=condition=ready pod \
  -l service=kvs-database \
  -n $NAMESPACE \
  --timeout=300s

kubectl wait --for=condition=ready pod \
  -l service=ns-dns \
  -n $NAMESPACE \
  --timeout=60s

# Print service endpoints
echo "[*] Service endpoints:"
kubectl get svc -n $NAMESPACE -o wide

# Check pod status
echo "[*] Pod status:"
kubectl get pods -n $NAMESPACE -o wide
