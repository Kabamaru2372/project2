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
