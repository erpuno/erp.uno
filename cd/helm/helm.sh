#!/bin/bash
# Helm Chart Initialization and Validation

set -e

CHART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="erp-uno"

echo "╔════════════════════════════════════════════════════════╗"
echo "║         Helm Chart Init & Validation                  ║"
echo "╚════════════════════════════════════════════════════════╝"

# Step 1: Verify Helm
echo -e "\n[1/4] Checking Helm..."
if ! command -v helm &> /dev/null; then
  echo "❌ Helm not installed"
  echo "   Install: https://helm.sh/docs/intro/install/"
  exit 1
fi

HELM_VERSION=$(helm version --short | grep -o 'v[0-9.]*')
echo "    ✓ Helm $HELM_VERSION"

# Check Helm v3+
if [[ $HELM_VERSION == v2* ]]; then
  echo "    ⚠ Helm v2 detected. Helm v3+ required."
  exit 1
fi

# Step 2: Verify Chart structure
echo -e "\n[2/4] Validating chart structure..."

if [ ! -f "$CHART_DIR/Chart.yaml" ]; then
  echo "❌ Chart.yaml not found in $CHART_DIR"
  exit 1
fi
echo "    ✓ Chart.yaml exists"

if [ ! -d "$CHART_DIR/templates" ]; then
  echo "❌ templates/ directory not found"
  exit 1
fi
echo "    ✓ templates/ directory exists"

if [ ! -f "$CHART_DIR/values.yaml" ]; then
  echo "❌ values.yaml not found"
  exit 1
fi
echo "    ✓ values.yaml exists"

# Step 3: Check .helmignore
echo -e "\n[3/4] Checking .helmignore..."

if [ -f "$CHART_DIR/.helmignore" ]; then
  echo "    Found .helmignore - removing (causes Helm v3+ issues)..."
  rm "$CHART_DIR/.helmignore"
  echo "    ✓ Removed"
else
  echo "    ⓘ No .helmignore (good)"
fi

# Step 4: Lint and validate
echo -e "\n[4/4] Linting chart..."

if helm lint "$CHART_DIR" 2>&1 | grep -q "1 chart(s) linted, 0 chart(s) failed"; then
  echo "    ✓ Lint passed"
else
  echo "    ⚠ Lint warnings (checking details)..."
  helm lint "$CHART_DIR"
fi

# Summary
echo -e "\n╔════════════════════════════════════════════════════════╗"
echo "║              Chart Ready to Deploy ✓                  ║"
echo "╚════════════════════════════════════════════════════════╝"

echo -e "\n📋 Chart Info:"
grep "name:\|version:\|description:" "$CHART_DIR/Chart.yaml" | sed 's/^/    /'

echo -e "\n🚀 Next Steps:\n"
echo "  1. Render templates:"
echo "     helm template erp-uno $CHART_DIR --values $CHART_DIR/values.yaml > erp-rendered.yaml"

echo -e "\n  2. Deploy to Kubernetes:"
echo "     kubectl apply -n $NAMESPACE -f erp-rendered.yaml"

echo -e "\n  3. Or use Helm directly:"
echo "     helm install erp-uno $CHART_DIR --namespace $NAMESPACE --create-namespace"

echo ""
