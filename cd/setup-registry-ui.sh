#!/bin/bash
# Deploy Docker Registry UI (optional)

set -e

NAMESPACE="erp-uno"

echo "╔════════════════════════════════════════════════════════╗"
echo "║          Docker Registry UI Deployment                ║"
echo "╚════════════════════════════════════════════════════════╝"

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry-ui
  namespace: $NAMESPACE
  labels:
    app: registry-ui
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registry-ui
  template:
    metadata:
      labels:
        app: registry-ui
    spec:
      containers:
      - name: ui
        image: joxit/docker-registry-ui:latest
        ports:
        - containerPort: 8080
        env:
        - name: REGISTRY_URL
          value: http://docker-registry:5000
        - name: REGISTRY_TITLE
          value: "ERP.uno Registry"
        - name: REGISTRY_DEFAULT_READONLY
          value: "false"
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: registry-ui
  namespace: $NAMESPACE
  labels:
    app: registry-ui
spec:
  type: ClusterIP
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP
  selector:
    app: registry-ui
EOF

echo "✓ Registry UI deployed"

# Wait for pod
echo -e "\nWaiting for Registry UI pod..."
kubectl wait --for=condition=ready pod \
  -l app=registry-ui \
  -n $NAMESPACE \
  --timeout=30s

echo -e "\n✓ Registry UI is ready"

echo -e "\nAccess Registry UI:"
echo "   kubectl port-forward -n $NAMESPACE svc/registry-ui 8080:8080"
echo "   → http://localhost:8080"
