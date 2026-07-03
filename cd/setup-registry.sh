#!/bin/bash
# Setup local Docker Registry on macOS + Kubernetes

set -e

NAMESPACE="erp-uno"
REGISTRY_HOST="registry.erp.uno"
REGISTRY_PORT="5000"

echo "╔════════════════════════════════════════════════════════╗"
echo "║     Docker Registry Setup (macOS + Kubernetes)        ║"
echo "╚════════════════════════════════════════════════════════╝"

# Step 1: Deploy Registry to Kubernetes
echo -e "\n[1/5] Deploying Docker Registry to Kubernetes..."

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-storage
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 50Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docker-registry
  namespace: $NAMESPACE
  labels:
    app: docker-registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: docker-registry
  template:
    metadata:
      labels:
        app: docker-registry
    spec:
      containers:
      - name: registry
        image: registry:2.8.3
        ports:
        - containerPort: 5000
        volumeMounts:
        - name: storage
          mountPath: /var/lib/registry
        resources:
          requests:
            cpu: 50m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 512Mi
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: registry-storage
---
apiVersion: v1
kind: Service
metadata:
  name: docker-registry
  namespace: $NAMESPACE
  labels:
    app: docker-registry
spec:
  type: ClusterIP
  ports:
  - port: 5000
    targetPort: 5000
    protocol: TCP
  selector:
    app: docker-registry
EOF

echo "    ✓ Registry deployment submitted"

# Wait for pod to be ready
echo -e "\n[2/5] Waiting for Registry pod to be ready (timeout 60s)..."
if kubectl wait --for=condition=ready pod \
    -l app=docker-registry \
    -n $NAMESPACE \
    --timeout=60s 2>/dev/null; then
  echo "    ✓ Registry pod is ready"
else
  echo "    ⚠ Registry pod startup timeout"
  echo "    Check logs: kubectl logs -n $NAMESPACE -l app=docker-registry"
fi

# Step 2: Add to /etc/hosts
echo -e "\n[3/5] Adding registry to /etc/hosts..."
if grep -q "$REGISTRY_HOST" /etc/hosts; then
  echo "    ⓘ $REGISTRY_HOST already in /etc/hosts"
else
  echo "    Adding $REGISTRY_HOST..."
  sudo tee -a /etc/hosts > /dev/null <<EOF
127.0.0.1 $REGISTRY_HOST
EOF
  echo "    ✓ Added to /etc/hosts"
fi

# Verify DNS
if ping -c 1 $REGISTRY_HOST &> /dev/null; then
  echo "    ✓ DNS resolution working"
else
  echo "    ⚠ DNS resolution may take a moment"
fi

# Step 3: Configure Docker daemon
echo -e "\n[4/5] Configuring Docker daemon..."

DOCKER_CONFIG="$HOME/.docker/daemon.json"

if [ ! -f "$DOCKER_CONFIG" ]; then
  echo "    Creating $DOCKER_CONFIG..."
  mkdir -p "$HOME/.docker"
  cat > "$DOCKER_CONFIG" <<EOF
{
  "insecure-registries": [
    "$REGISTRY_HOST:$REGISTRY_PORT",
    "localhost:$REGISTRY_PORT"
  ]
}
EOF
else
  # Check if already configured
  if grep -q "$REGISTRY_HOST" "$DOCKER_CONFIG"; then
    echo "    ⓘ $REGISTRY_HOST already in Docker config"
  else
    echo "    ⚠ Please manually add to $DOCKER_CONFIG:"
    echo "      {\"insecure-registries\": [\"$REGISTRY_HOST:$REGISTRY_PORT\"]}"
  fi
fi

echo "    ✓ Docker daemon config ready"
echo "    Config: $DOCKER_CONFIG"

# Step 4: Port-forward
echo -e "\n[5/5] Setting up port-forward..."

# Kill existing port-forward
pkill -f "port-forward.*docker-registry" 2>/dev/null || true
sleep 1

# Start new port-forward
kubectl port-forward -n $NAMESPACE svc/docker-registry $REGISTRY_PORT:$REGISTRY_PORT &
PF_PID=$!

sleep 2

# Test connectivity
echo "    Testing registry connectivity..."
if curl -s http://localhost:$REGISTRY_PORT/v2/ > /dev/null 2>&1; then
  echo "    ✓ Registry accessible at http://localhost:$REGISTRY_PORT"
else
  echo "    ⚠ Registry not yet responsive, waiting..."
  sleep 3
fi

echo "    ✓ Port-forward started (PID: $PF_PID)"

# Summary
echo -e "\n╔════════════════════════════════════════════════════════╗"
echo "║                 Setup Complete ✓                        ║"
echo "╚════════════════════════════════════════════════════════╝"

echo -e "\n📋 Registry Configuration:"
echo "   URL: http://$REGISTRY_HOST:$REGISTRY_PORT"
echo "   Namespace: $NAMESPACE"
echo "   Storage: 50Gi (PVC)"

echo -e "\n🐳 Build & Push Images:"
echo "   docker build -t $REGISTRY_HOST:$REGISTRY_PORT/erpuno/myservice:2024.6.15 ."
echo "   docker push $REGISTRY_HOST:$REGISTRY_PORT/erpuno/myservice:2024.6.15"

echo -e "\n✅ Verify Registry:"
echo "   curl http://localhost:$REGISTRY_PORT/v2/"
echo "   curl http://localhost:$REGISTRY_PORT/v2/erpuno/myservice/tags/list"

echo -e "\n🖥️  Helm Deployment:"
echo "   helm upgrade erp-uno . -n $NAMESPACE \\"
echo "     --set global.registry=$REGISTRY_HOST:$REGISTRY_PORT"

echo -e "\n⚠️  Note: Restart Docker Desktop if you modified daemon.json"
echo "   • Open Docker Desktop UI"
echo "   • Or: open -a Docker"

echo -e "\n📊 Monitor Registry:"
echo "   kubectl get pods -n $NAMESPACE -l app=docker-registry -w"
echo "   kubectl logs -n $NAMESPACE -l app=docker-registry -f"

echo -e "\n📚 Optional: Deploy Registry UI"
echo "   bash setup-registry-ui.sh"

echo ""
