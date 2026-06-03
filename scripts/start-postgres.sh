#!/usr/bin/env bash
set -euo pipefail

profile="bernstein"

echo "1. Wait for Kubernetes API"
until minikube --profile="${profile}" kubectl -- get nodes >/dev/null 2>&1; do
  echo "Kubernetes API is not ready yet; retrying..."
  sleep 5
done

echo "2. Apply PostgreSQL manifests"
minikube --profile="${profile}" kubectl -- apply -f db/postgres/secret.yaml
minikube --profile="${profile}" kubectl -- apply -f db/postgres/configmap.yaml
minikube --profile="${profile}" kubectl -- apply -f db/postgres/volume.yaml
minikube --profile="${profile}" kubectl -- apply -f db/postgres/deployment.yaml
minikube --profile="${profile}" kubectl -- apply -f db/postgres/service.yaml

echo "3. Wait for PostgreSQL rollout"
minikube --profile="${profile}" kubectl -- rollout status deployment/postgres-deployment --timeout=180s

echo "4. Wait for PostgreSQL readiness"
postgres_pod="$(minikube --profile="${profile}" kubectl -- get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')"
until minikube --profile="${profile}" kubectl -- exec "${postgres_pod}" -- pg_isready -U admin -d postgresdb >/dev/null 2>&1; do
  echo "PostgreSQL is not ready yet; retrying..."
  sleep 2
done

echo "5. Apply database schema"
minikube --profile="${profile}" kubectl -- exec -i "${postgres_pod}" -- psql -U admin -d postgresdb < db/postgres/schema.sql

echo "6. Show PostgreSQL resources"
minikube --profile="${profile}" kubectl -- get configmap postgres-configmap
minikube --profile="${profile}" kubectl -- get secret postgres-secret
minikube --profile="${profile}" kubectl -- get deployment postgres-deployment
minikube --profile="${profile}" kubectl -- get service postgres-service
minikube --profile="${profile}" kubectl -- get pvc postgres-claim
minikube --profile="${profile}" kubectl -- get pods -l app=postgres
