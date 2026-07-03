#!/bin/bash
# Deploy monitoring stack (Prometheus + Grafana)

set -e

NAMESPACE="erp-uno"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔════════════════════════════════════════════════════════╗"
echo "║         Deploy Monitoring Stack                       ║"
echo "╚════════════════════════════════════════════════════════╝"

# Step 1: Verify namespace
echo -e "\n[1/3] Verifying namespace..."
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
  echo "❌ Namespace $NAMESPACE not found"
  echo "   Run: bash $SCRIPT_DIR/init.sh"
  exit 1
fi
echo "    ✓ Namespace exists"

# Step 2: Apply Prometheus
echo -e "\n[2/3] Deploying Prometheus..."
if [ -f "$SCRIPT_DIR/k8s/prometheus.yaml" ]; then
  kubectl apply -n $NAMESPACE -f "$SCRIPT_DIR/k8s/prometheus.yaml"
  echo "    ✓ Prometheus deployed"
else
  echo "    ⚠ prometheus.yaml not found"
fi

# Step 3: Apply Grafana
echo -e "\n[3/3] Deploying Grafana..."
if [ -f "$SCRIPT_DIR/k8s/grafana.yaml" ]; then
  kubectl apply -n $NAMESPACE -f "$SCRIPT_DIR/k8s/grafana.yaml"
  echo "    ✓ Grafana deployed"
else
  echo "    ⚠ grafana.yaml not found"
fi

# Summary
echo -e "\n╔════════════════════════════════════════════════════════╗"
echo "║              Monitoring Stack Ready ✓                 ║"
echo "╚════════════════════════════════════════════════════════╝"

echo -e "\n📊 Access Services:\n"
echo "   Prometheus:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus-demo 9090:9090"
echo "   → http://localhost:9090"

echo -e "\n   Grafana:"
echo "   kubectl port-forward -n $NAMESPACE svc/grafana-demo 3000:3000"
echo "   → http://localhost:3000"
echo "   User: admin | Password: admin"

echo -e "\n📋 Check Status:"
echo "   kubectl get pods -n $NAMESPACE -w"
echo ""
