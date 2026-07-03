#!/bin/bash
# Deployment Prerequisites Checklist

echo "╔════════════════════════════════════════════════════════╗"
echo "║        ERP.uno Deployment Prerequisites Check         ║"
echo "╚════════════════════════════════════════════════════════╝"

PASS="✓"
FAIL="✗"
WARN="⚠"

# Check 1: kubectl installed
echo -e "\n[1] kubectl CLI"
if command -v kubectl &> /dev/null; then
  kubectl_version=$(kubectl version --client --short 2>/dev/null | grep "Client" | awk '{print $3}')
  echo "    $PASS kubectl $kubectl_version installed"
else
  echo "    $FAIL kubectl NOT found"
  echo "       Install: https://kubernetes.io/docs/tasks/tools/"
fi

# Check 2: Helm installed
echo -e "\n[2] Helm 3"
if command -v helm &> /dev/null; then
  helm_version=$(helm version --short)
  echo "    $PASS Helm $helm_version installed"
else
  echo "    $FAIL Helm NOT found"
  echo "       Install: https://helm.sh/docs/intro/install/"
fi

# Check 3: Kubernetes cluster accessible
echo -e "\n[3] Kubernetes Cluster"
if kubectl cluster-info &>/dev/null; then
  k8s_version=$(kubectl version --short 2>/dev/null | grep "Server" | awk '{print $3}')
  node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
  echo "    $PASS Cluster accessible"
  echo "       Version: $k8s_version"
  echo "       Nodes: $node_count"
  
  # Check node capacity
  total_cpu=$(kubectl get nodes -o json 2>/dev/null | jq '.items[].status.allocatable.cpu' | sed 's/"//g' | sed 's/m$//' | awk '{s+=$1} END {print s}')
  total_mem=$(kubectl get nodes -o json 2>/dev/null | jq '.items[].status.allocatable.memory' | sed 's/"//g' | sed 's/Ki$//' | awk '{s+=$1} END {print s}')
  total_mem_gb=$((total_mem / 1024 / 1024))
  
  echo "       Total CPU: ${total_cpu}m"
  echo "       Total Memory: ${total_mem_gb}GB"
  
  if [ "$total_cpu" -lt 4000 ] || [ "$total_mem_gb" -lt 8 ]; then
    echo "       $WARN Cluster resources may be tight for 25 services"
    echo "          Recommended: ≥4 CPU cores, ≥16GB RAM"
  fi
else
  echo "    $FAIL Cluster not accessible"
  echo "       Setup: https://kubernetes.io/docs/setup/"
  echo "       Or use: Docker Desktop, Minikube, KinD, etc."
fi

# Check 4: Default StorageClass
echo -e "\n[4] Storage"
default_sc=$(kubectl get sc -o json 2>/dev/null | jq '.items[] | select(.metadata.annotations."storageclass.kubernetes.io/is-default-class"=="true") | .metadata.name' -r 2>/dev/null || echo "")
if [ -n "$default_sc" ]; then
  echo "    $PASS Default StorageClass: $default_sc"
else
  available_sc=$(kubectl get sc --no-headers 2>/dev/null | wc -l)
  if [ "$available_sc" -gt 0 ]; then
    echo "    $WARN No default StorageClass"
    echo "       Available: $(kubectl get sc -o name | cut -d'/' -f2 | tr '\n' ', ')"
  else
    echo "    $FAIL No StorageClass available"
    echo "       Install: Longhorn, Portworx, Ceph, or use 'local-path-provisioner'"
  fi
fi

# Check 5: Ingress Controller
echo -e "\n[5] Ingress Controller"
ingress_ctrl=$(kubectl get deployment -A -o json 2>/dev/null | jq '.items[] | select(.spec.template.spec.containers[].image | contains("nginx") or contains("ingress")) | .metadata.name' -r 2>/dev/null | head -1)
if [ -n "$ingress_ctrl" ]; then
  echo "    $PASS Ingress controller found: $ingress_ctrl"
else
  echo "    $WARN No Ingress controller detected"
  echo "       (Required for external access to Nitro Portal)"
  echo "       Install: kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.0/deploy/static/provider/cloud/deploy.yaml"
fi

# Check 6: DNS (CoreDNS)
echo -e "\n[6] Cluster DNS"
if kubectl get deployment -n kube-system coredns &>/dev/null; then
  echo "    $PASS CoreDNS available"
else
  echo "    $WARN CoreDNS not found"
  echo "       Internal service discovery may fail"
fi

# Check 7: Namespace ready
echo -e "\n[7] Namespace Setup"
if kubectl get namespace erp-uno &>/dev/null; then
  echo "    $WARN Namespace 'erp-uno' already exists"
  echo "       To redeploy: kubectl delete namespace erp-uno"
else
  echo "    $PASS Namespace 'erp-uno' ready to create"
fi

# Check 8: Image Registry access
echo -e "\n[8] Image Registry"
registry="${REGISTRY:-registry.erp.uno}"
echo "    Configured: $registry"
echo "    $WARN Ensure images are accessible from cluster"
echo "       For private registries: set ImagePullSecret"

# Check 9: Docker installed (for compose testing)
echo -e "\n[9] Docker (for local testing with docker-compose)"
if command -v docker &> /dev/null; then
  docker_version=$(docker --version 2>/dev/null | awk '{print $3}')
  echo "    $PASS Docker $docker_version installed"
else
  echo "    $WARN Docker NOT found"
  echo "       (Optional, needed only for local testing)"
fi

# Summary
echo -e "\n╔════════════════════════════════════════════════════════╗"
echo "║                      Next Steps                        ║"
echo "╚════════════════════════════════════════════════════════╝"

echo -e "\nIf all checks pass (or only warnings), run:\n"
echo "  bash deploy-start.sh"

echo -e "\nOr deploy manually:\n"
echo "  cd helm"
echo "  helm install erp-uno . --namespace erp-uno --create-namespace"

echo ""
