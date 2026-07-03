kubectl delete namespace erp-uno
kubectl create namespace erp-uno
kubectl apply -n erp-uno -f erp-demo.yaml
helm template erp-uno . --values values-demo.yaml > erp-demo.yaml
kubectl port-forward -n erp-uno svc/prometheus-demo 9090:9090 # http://localhost:9090
kubectl get all -n erp-uno
