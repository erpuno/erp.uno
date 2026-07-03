kubectl create namespace erp-uno --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f helm/templates/ -n erp-uno
