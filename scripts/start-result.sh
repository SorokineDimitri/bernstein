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

echo "2. Check PostgreSQL resources"
if ! minikube --profile="${profile_name}" kubectl -- get service postgres-service >/dev/null 2>&1; then
  echo "PostgreSQL service is missing."
  echo "Run this first:"
  echo "./scripts/start-postgres.sh"
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

echo "3. Apply Result manifests"
minikube --profile="${profile_name}" kubectl -- apply -f services/result/deployment.yaml
minikube --profile="${profile_name}" kubectl -- apply -f services/result/service.yaml
minikube --profile="${profile_name}" kubectl -- apply -f ingress.yaml

echo "4. Wait for Result rollout"
minikube --profile="${profile_name}" kubectl -- rollout status deployment/result --timeout=180s

echo "5. Wait for Result service endpoints"
until minikube --profile="${profile_name}" kubectl -- get endpoints result -o jsonpath='{.subsets[*].addresses[*].ip}' | grep -q .; do
  echo "Result service endpoints are not ready yet; retrying..."
  sleep 2
done

echo "6. Show Result resources"
minikube --profile="${profile_name}" kubectl -- get deployment result
minikube --profile="${profile_name}" kubectl -- get service result
minikube --profile="${profile_name}" kubectl -- get ingress app-ingress
minikube --profile="${profile_name}" kubectl -- get pods -l app=result
