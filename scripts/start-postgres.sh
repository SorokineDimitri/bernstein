#!/usr/bin/env bash
set -euo pipefail

profile="bernstein"

echo "1. Wait for Kubernetes API"
until minikube --profile="${profile}" kubectl -- get nodes >/dev/null 2>&1; do
  echo "Kubernetes API is not ready yet; retrying..."
  sleep 5
done

echo "2. Create PostgreSQL secret"
read -r -p "PostgreSQL username: " postgres_user
read -r -s -p "PostgreSQL password: " postgres_password
echo

if [[ -z "${postgres_user}" || -z "${postgres_password}" ]]; then
  echo "PostgreSQL username and password cannot be empty."
  exit 1
fi

minikube --profile="${profile}" kubectl -- create secret generic postgres-secret \
  --from-literal=user="${postgres_user}" \
  --from-literal=password="${postgres_password}" \
  --dry-run=client \
  -o yaml | minikube --profile="${profile}" kubectl -- apply -f -

echo "3. Apply PostgreSQL manifests"
minikube --profile="${profile}" kubectl -- apply -f db/postgres/configmap.yaml
minikube --profile="${profile}" kubectl -- apply -f db/postgres/volume.yaml
minikube --profile="${profile}" kubectl -- apply -f db/postgres/deployment.yaml
minikube --profile="${profile}" kubectl -- apply -f db/postgres/service.yaml

echo "4. Wait for PostgreSQL rollout"
minikube --profile="${profile}" kubectl -- rollout status deployment/postgres-deployment --timeout=180s

echo "5. Wait for PostgreSQL readiness"
postgres_pod="$(minikube --profile="${profile}" kubectl -- get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')"
deadline=$((SECONDS + 180))

until minikube --profile="${profile}" kubectl -- exec "${postgres_pod}" -- env PGPASSWORD="${postgres_password}" pg_isready -U "${postgres_user}" -d postgresdb >/dev/null 2>&1; do
  if (( SECONDS >= deadline )); then
    echo "PostgreSQL is not ready with the provided credentials."
    echo "If the database volume already existed, Postgres kept the old initialized user/password."
    echo "Use the same credentials as the existing database, or reset Minikube to recreate the volume."
    exit 1
  fi

  echo "PostgreSQL is not ready yet; retrying..."
  sleep 2
done

echo "6. Apply database schema"
minikube --profile="${profile}" kubectl -- exec -i "${postgres_pod}" -- env PGPASSWORD="${postgres_password}" psql -U "${postgres_user}" -d postgresdb < db/postgres/schema.sql

echo "7. Show PostgreSQL resources"
minikube --profile="${profile}" kubectl -- get configmap postgres-configmap
minikube --profile="${profile}" kubectl -- get secret postgres-secret
minikube --profile="${profile}" kubectl -- get deployment postgres-deployment
minikube --profile="${profile}" kubectl -- get service postgres-service
minikube --profile="${profile}" kubectl -- get pvc postgres-claim
minikube --profile="${profile}" kubectl -- get pods -l app=postgres
