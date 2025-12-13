# Instructions

1. Create EKS cluster

```
./cluster-config.sh
```

_You will be prompted to create a new cluster by adding a cluster name and a recognized region._

2. Create secrets on EKS cluster

```
kubectl create secret generic db-credentials --from-literal=POSTGRES_USER=<user> --from-literal=POSTGRES_PASSWORD=<password> --from-literal=POSTGRES_DB=<db_name>
```

3. Set up **POSTGRES** container:
   _storage class -> persistent volume claim -> deployment -> service_

```
# IN THIS ORDER!
kubectl apply -f postgres-sc.yaml
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml
```

4. Set up **REDIS** container:
   _storage class -> persistent volume claim -> deployment -> service_

```
# IN THIS ORDER!
kubectl apply -f redis-sc.yaml
kubectl apply -f redis-pvc.yaml
kubectl apply -f redis-deployment.yaml
kubectl apply -f redis-service.yaml
```

5. Set up **WORKER** container:
   _deployment -> service_

```
# IN THIS ORDER!
kubectl apply -f worker-deployment.yaml
kubectl apply -f worker-service.yaml
```

6. Set up **VOTE** container:
   _deployment -> service_

```
# IN THIS ORDER!
kubectl apply -f vote-deployment.yaml
kubectl apply -f vote-service.yaml
```

7. Set up **RESULT** container:
   _deployment -> service_

```
# IN THIS ORDER!
kubectl apply -f result-deployment.yaml
kubectl apply -f result-service.yaml
```

# NOTES:

Verify **POSTGRES** DB with:

```
# Get into container
kubectl exec --stdin --tty postgres-container-name -- /bin/bash
# Then
psql -h postgres-service -U <user> -d <db_name>
```
