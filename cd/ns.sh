kubectl delete namespace erp-uno
kubectl create namespace erp-uno
kubectl apply -n erp-uno -f erp-demo.yaml
helm template erp-uno . --values values-demo.yaml > erp-demo.yaml
kubectl port-forward -n erp-uno svc/prometheus 8401:8401
