#!/usr/bin/env bash
set -euo pipefail

profile_name="bernstein"
timeout_seconds=900

echo "1. Wait for Kubernetes API"
deadline=$((SECONDS + timeout_seconds))

until minikube --profile="${profile_name}" kubectl -- get nodes >/dev/null 2>&1; do
  if (( SECONDS >= deadline )); then
    echo "Kubernetes API is not ready after ${timeout_seconds}s."
    echo "Check Minikube status:"
    echo "./scripts/status-minikube.sh"
    exit 1
  fi

  echo "Kubernetes API is not ready yet; retrying..."
  sleep 5
done

minikube --profile="${profile_name}" kubectl -- get nodes

echo "2. Check Redis and PostgreSQL resources"
if ! minikube --profile="${profile_name}" kubectl -- get service redis-service >/dev/null 2>&1; then
  echo "Redis service is missing."
  echo "Run this first:"
  echo "./scripts/start-redis.sh"
  exit 1
fi

if ! minikube --profile="${profile_name}" kubectl -- get service postgres-service >/dev/null 2>&1; then
  echo "PostgreSQL service is missing."
  echo "Run this first:"
  echo "./scripts/start-postgres.sh"
  exit 1
fi

if ! minikube --profile="${profile_name}" kubectl -- get configmap redis-configmap >/dev/null 2>&1; then
  echo "Redis ConfigMap is missing."
  echo "Run this first:"
  echo "./scripts/start-redis.sh"
  exit 1
fi

if ! minikube --profile="${profile_name}" kubectl -- get configmap postgres-configmap >/dev/null 2>&1; then
  echo "PostgreSQL ConfigMap is missing."
  echo "Run this first:"
  echo "./scripts/start-postgres.sh"
  exit 1
fi

if ! minikube --profile="${profile_name}" kubectl -- get secret postgres-secret >/dev/null 2>&1; then
  echo "PostgreSQL Secret is missing."
  echo "Run this first:"
  echo "./scripts/start-postgres.sh"
  exit 1
fi

echo "3. Wait for Redis and PostgreSQL endpoints"
until minikube --profile="${profile_name}" kubectl -- get endpoints redis-service -o jsonpath='{.subsets[*].addresses[*].ip}' | grep -q .; do
  echo "Redis endpoints are not ready yet; retrying..."
  sleep 2
done

until minikube --profile="${profile_name}" kubectl -- get endpoints postgres-service -o jsonpath='{.subsets[*].addresses[*].ip}' | grep -q .; do
  echo "PostgreSQL endpoints are not ready yet; retrying..."
  sleep 2
done

echo "4. Apply Worker manifest"
minikube --profile="${profile_name}" kubectl -- apply -f services/worker/deployment.yaml

echo "5. Wait for Worker rollout"
minikube --profile="${profile_name}" kubectl -- rollout status deployment/worker --timeout=180s

echo "6. Show Worker resources"
minikube --profile="${profile_name}" kubectl -- get deployment worker
minikube --profile="${profile_name}" kubectl -- get pods -l app=worker
