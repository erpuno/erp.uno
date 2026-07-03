#!/bin/bash
# Initialize ERP.uno deployment environment

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║         ERP.uno Initialization (Step 0)               ║"
echo "╚════════════════════════════════════════════════════════╝"

NAMESPACE="erp-uno"

# Step 1: Verify cluster access
echo -e "\n[1/4] Verifying Kubernetes cluster..."
if ! kubectl cluster-info &>/dev/null; then
  echo "❌ ERROR: Kubernetes cluster not accessible"
  echo "   Make sure kubectl is configured and cluster is running"
  exit 1
fi
echo "    ✓ Cluster accessible"

# Step 2: Create namespace
echo -e "\n[2/4] Creating namespace '$NAMESPACE'..."
if kubectl get namespace $NAMESPACE &>/dev/null; then
  echo "    ⓘ Namespace already exists"
else
  kubectl create namespace $NAMESPACE
  echo "    ✓ Namespace created"
fi

# Step 3: Label namespace (for monitoring/logging)
echo -e "\n[3/4] Labeling namespace..."
kubectl label namespace $NAMESPACE \
  name=$NAMESPACE \
  environment=production \
  --overwrite=true 2>/dev/null
echo "    ✓ Labels applied"

# Step 4: Summary
echo -e "\n[4/4] Initialization Summary"
echo "    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

NAMESPACE_INFO=$(kubectl get namespace $NAMESPACE -o jsonpath='{.metadata.creationTimestamp}')
echo "    ✓ Namespace: $NAMESPACE"
echo "    ✓ Created: $NAMESPACE_INFO"

echo -e "\n╔════════════════════════════════════════════════════════╗"
echo "║              Ready for next steps ✓                   ║"
echo "╚════════════════════════════════════════════════════════╝"

echo -e "\n🚀 Next: Deploy Docker Registry\n"
echo "   bash setup-registry.sh"
echo ""
