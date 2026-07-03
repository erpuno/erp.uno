#!/bin/bash
# Backup stateful services

set -eu

NAMESPACE="erp-uno"
BACKUP_DIR="${BACKUP_DIR:-.backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

backup_pvc() {
  local pvc=$1
  local pod=$2
  local mount_path=$3
  
  echo "[*] Backing up $pvc..."
  
  kubectl exec -n $NAMESPACE $pod -- tar czf - $mount_path | \
    gzip > $BACKUP_DIR/${pvc}_${TIMESTAMP}.tar.gz
  
  echo "[✓] Backed up to $BACKUP_DIR/${pvc}_${TIMESTAMP}.tar.gz"
}

# Backup critical stateful services
backup_pvc "kvs-data" "kvs-database-0" "/var/lib/kvs"
backup_pvc "prometheus-data" "prometheus-0" "/prometheus"
backup_pvc "loki-data" "loki-0" "/loki"

# Optional: Backup Mnesia/RocksDB from application services
for service in acc-accounting itsm-incidents wms-warehouse; do
  if kubectl get pod -n $NAMESPACE ${service}-0 &>/dev/null; then
    backup_pvc "${service}-data" "${service}-0" "/var/lib/${service}"
  fi
done

echo "[✓] Backup complete: $BACKUP_DIR"
