#!/bin/bash
# Monitor ERP.uno cluster state

set -eu

NAMESPACE="erp-uno"

echo "=== Cluster Overview ==="
kubectl get nodes -o wide

echo -e "\n=== Namespace Resources ==="
kubectl get all -n $NAMESPACE -o wide

echo -e "\n=== StatefulSet Status ==="
kubectl get statefulset -n $NAMESPACE -o wide

echo -e "\n=== Pod Resource Usage ==="
kubectl top pods -n $NAMESPACE --sort-by=memory

echo -e "\n=== HPA Status ==="
kubectl get hpa -n $NAMESPACE

echo -e "\n=== PVC Status ==="
kubectl get pvc -n $NAMESPACE -o wide

echo -e "\n=== Service Endpoints ==="
kubectl get endpoints -n $NAMESPACE

echo -e "\n=== Events ==="
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -20
