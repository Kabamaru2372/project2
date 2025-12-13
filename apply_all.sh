# POSTGRESS CONTAINER
kubectl apply -f postgres-sc.yaml
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# REDIS CONTAINER
kubectl apply -f redis-sc.yaml
kubectl apply -f redis-pvc.yaml
kubectl apply -f redis-deployment.yaml
kubectl apply -f redis-service.yaml

# WORKER CONTAINER
kubectl apply -f worker-deployment.yaml
kubectl apply -f worker-service.yaml

# VOTE CONTAINER
kubectl apply -f vote-deployment.yaml
kubectl apply -f vote-service.yaml

# RESULT CONTAINER
kubectl apply -f result-deployment.yaml
kubectl apply -f result-service.yaml

# INGRESS
kubectl apply -f ingress.yaml