echo
read -p "Enter POSTGRES_USER: " POSTGRES_USER
read -p "Enter POSTGRES_PASSWORD: " POSTGRES_PASSWORD
read -p "Enter POSTGRES_DB: " POSTGRES_DB

kubectl create secret generic db-credentials --from-literal=POSTGRES_USER=$POSTGRES_USER--from-literal=POSTGRES_PASSWORD=$POSTGRES_PASSWORD --from-literal=POSTGRES_DB=$POSTGRES_DB

# POSTGRESS CONTAINER
kubectl apply -f ./K8s/postgres-sc.yaml
kubectl apply -f ./K8s/postgres-pvc.yaml
kubectl apply -f ./K8s/postgres-deployment.yaml
kubectl apply -f ./K8s/postgres-service.yaml

# REDIS CONTAINER
kubectl apply -f ./K8s/redis-sc.yaml
kubectl apply -f ./K8s/redis-pvc.yaml
kubectl apply -f ./K8s/redis-deployment.yaml
kubectl apply -f ./K8s/redis-service.yaml

# WORKER CONTAINER
kubectl apply -f ./K8s/worker-deployment.yaml
kubectl apply -f ./K8s/worker-service.yaml

# VOTE CONTAINER
kubectl apply -f ./K8s/vote-deployment.yaml
kubectl apply -f ./K8s/vote-service.yaml

# RESULT CONTAINER
kubectl apply -f ./K8s/result-deployment.yaml
kubectl apply -f ./K8s/result-service.yaml

# INGRESS
kubectl apply -f ./K8s/ingress.yaml