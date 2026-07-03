#!/bin/bash
# Scale services up/down

set -eu

NAMESPACE="erp-uno"

scale_service() {
  local service=$1
  local replicas=$2
  local kind=$3  # Deployment or StatefulSet
  
  echo "[*] Scaling $service to $replicas replicas"
  kubectl scale $kind $service --replicas=$replicas -n $NAMESPACE
}

# Scale WebSocket/chat services for bursty traffic
scale_service "chat-messenger" "${CHAT_REPLICAS:-5}" "Deployment"
scale_service "n2o-server" "${N2O_REPLICAS:-4}" "Deployment"
scale_service "nitro-portal" "${NITRO_REPLICAS:-3}" "Deployment"

echo "[✓] Scaling complete"
