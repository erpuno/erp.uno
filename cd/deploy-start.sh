#!/bin/bash
# Quick Start: Deploy ERP.uno on Kubernetes

set -eu

REPO_DIR="/tmp/erp.uno"
NAMESPACE="erp-uno"
DOMAIN="${DOMAIN:-erp.uno}"
ENVIRONMENT="${ENVIRONMENT:-production}"
REGISTRY="${REGISTRY:-registry.erp.uno}"

echo "╔════════════════════════════════════════════════════════╗"
echo "║          ERP.uno Kubernetes Deployment                ║"
echo "╚════════════════════════════════════════════════════════╝"

# Step 1: Verify Kubernetes cluster
echo -e "\n[1/6] Verifying Kubernetes cluster..."
if ! kubectl cluster-info &>/dev/null; then
  echo "❌ ERROR: Kubernetes cluster not accessible"
  echo "   Make sure: kubectl is configured and cluster is running"
  exit 1
fi

K8S_VERSION=$(kubectl version --short 2>/dev/null | grep "Server" | awk '{print $3}')
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
echo "    ✓ Cluster version: $K8S_VERSION"
echo "    ✓ Nodes: $NODE_COUNT"

# Step 2: Create namespace
echo -e "\n[2/6] Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
echo "    ✓ Namespace '$NAMESPACE' ready"

# Step 3: Apply StorageClass (local-path for single-node, adjust for multi-node)
echo -e "\n[3/6] Setting up storage..."
STORAGE_CLASS=$(kubectl get sc -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "local-path")
if [ "$STORAGE_CLASS" != "local-path" ]; then
  echo "    ✓ Using existing StorageClass: $STORAGE_CLASS"
else
  echo "    ! StorageClass 'local-path' not found"
  echo "      Applying default StorageClass (local-path provisioner)..."
  kubectl apply -f $REPO_DIR/cd/k8s/storage-classes.yaml 2>/dev/null || echo "      (skipped, may require manual setup)"
fi

# Step 4: Deploy Helm chart
echo -e "\n[4/6] Deploying Helm chart..."
if ! command -v helm &> /dev/null; then
  echo "❌ ERROR: Helm not installed"
  echo "   Install from: https://helm.sh/docs/intro/install/"
  exit 1
fi

HELM_VERSION=$(helm version --short)
echo "    Helm version: $HELM_VERSION"

cd $REPO_DIR/cd/helm

helm upgrade --install erp-uno . \
  --namespace $NAMESPACE \
  --values values.yaml \
  --set global.domain=$DOMAIN \
  --set global.environment=$ENVIRONMENT \
  --set global.registry=$REGISTRY \
  --timeout 5m \
  --wait 2>&1 | tail -5

echo "    ✓ Helm deployment complete"

# Step 5: Wait for critical services
echo -e "\n[5/6] Waiting for critical services (timeout 3m)..."

CRITICAL_SERVICES=("ns-dns" "kvs-database" "ias-auth")
for svc in "${CRITICAL_SERVICES[@]}"; do
  echo -n "    Waiting for $svc... "
  if kubectl wait --for=condition=ready pod \
      -l service=$svc \
      -n $NAMESPACE \
      --timeout=180s 2>/dev/null; then
    echo "✓"
  else
    echo "⚠ (timeout, check logs)"
  fi
done

# Step 6: Show deployment summary
echo -e "\n[6/6] Deployment Summary"
echo "    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n    Pod Status:"
kubectl get pods -n $NAMESPACE -o wide 2>/dev/null | awk 'NR==1 || NR<=11 {print "    "$0}' || echo "    (pods loading)"

echo -e "\n    Service Endpoints:"
kubectl get svc -n $NAMESPACE -o wide 2>/dev/null | awk 'NR==1 || NR<=6 {print "    "$0}' || echo "    (services loading)"

echo -e "\n    PVC Status:"
kubectl get pvc -n $NAMESPACE 2>/dev/null | awk 'NR==1 || NR<=6 {print "    "$0}' || echo "    (no PVCs yet)"

echo -e "\n    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Show next steps
echo -e "\n✓ Deployment started! Next steps:\n"

echo "  1️⃣  Monitor deployment:"
echo "     kubectl get pods -n $NAMESPACE -w"

echo -e "\n  2️⃣  View logs:"
echo "     kubectl logs -n $NAMESPACE -l service=ns-dns -f"

echo -e "\n  3️⃣  Port-forward to UI (Nitro Portal):"
echo "     kubectl port-forward -n $NAMESPACE svc/nitro-portal 8510:8510"
echo "     → Open http://localhost:8510"

echo -e "\n  4️⃣  Access Grafana monitoring:"
echo "     kubectl port-forward -n $NAMESPACE svc/grafana 8402:8402"
echo "     → Open http://localhost:8402 (user: admin, pass: admin)"

echo -e "\n  5️⃣  Check all resources:"
echo "     kubectl get all -n $NAMESPACE"

echo -e "\n  6️⃣  Describe deployment:"
echo "     kubectl describe deployment -n $NAMESPACE <service-name>"

echo -e "\n  📖 Full documentation:"
echo "     cat $REPO_DIR/cd/ARCHITECTURE.txt"

echo -e "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Deploy timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""
