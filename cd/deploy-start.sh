#!/bin/bash
# Deploy ERP.uno Helm Chart

set -e

NAMESPACE="erp-uno"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$SCRIPT_DIR/helm"

echo "╔════════════════════════════════════════════════════════╗"
echo "║        ERP.uno Helm Chart Deployment                  ║"
echo "╚════════════════════════════════════════════════════════╝"

# Step 1: Verify prerequisites
echo -e "\n[1/5] Verifying prerequisites..."
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
  echo "❌ Namespace $NAMESPACE not found"
  echo "   Run: bash $SCRIPT_DIR/init.sh"
  exit 1
fi
echo "    ✓ Namespace exists"

if ! command -v helm &> /dev/null; then
  echo "❌ Helm not installed"
  exit 1
fi
echo "    ✓ Helm installed"

# Step 2: Apply storage classes
echo -e "\n[2/5] Applying storage configuration..."
kubectl apply -f "$SCRIPT_DIR/k8s/storage-class.yaml"
echo "    ✓ StorageClass ready"

# Step 3: Render Helm chart
echo -e "\n[3/5] Rendering Helm chart..."
RENDERED_FILE="/tmp/erp-uno-rendered.yaml"

helm template erp-uno "$CHART_DIR" \
  --namespace $NAMESPACE \
  --values "$CHART_DIR/values.yaml" > "$RENDERED_FILE"

if [ ! -f "$RENDERED_FILE" ] || [ ! -s "$RENDERED_FILE" ]; then
  echo "❌ Failed to render Helm chart"
  exit 1
fi
echo "    ✓ Chart rendered: $RENDERED_FILE"

# Step 4: Deploy via kubectl
echo -e "\n[4/5] Deploying ERP.uno..."
kubectl apply -n $NAMESPACE -f "$RENDERED_FILE"
echo "    ✓ Deployment applied"

# Step 5: Deploy monitoring stack
echo -e "\n[5/5] Setting up monitoring..."
bash "$SCRIPT_DIR/monitoring.sh"

# Summary
echo -e "\n╔════════════════════════════════════════════════════════╗"
echo "║              Deployment Complete ✓                    ║"
echo "╚════════════════════════════════════════════════════════╝"

echo -e "\n📊 Check Status:\n"
echo "   kubectl get pods -n $NAMESPACE -w"
echo "   kubectl get svc -n $NAMESPACE"
echo "   kubectl get pvc -n $NAMESPACE"

echo -e "\n🌐 Access Services:\n"
echo "   Prometheus: kubectl port-forward -n $NAMESPACE svc/prometheus-demo 9090:9090"
echo "   Grafana: kubectl port-forward -n $NAMESPACE svc/grafana-demo 3000:3000"

echo ""
