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

echo "2. Check Redis service"
if ! minikube --profile="${profile_name}" kubectl -- get service redis-service >/dev/null 2>&1; then
  echo "Redis service is missing."
  echo "Run this first:"
  echo "./scripts/start-redis.sh"
  exit 1
fi

echo "3. Apply Poll manifests"
minikube --profile="${profile_name}" kubectl -- apply -f services/poll/deployment.yaml
minikube --profile="${profile_name}" kubectl -- apply -f services/poll/service.yaml
minikube --profile="${profile_name}" kubectl -- apply -f ingress.yaml

echo "4. Show Poll resources"
minikube --profile="${profile_name}" kubectl -- get deployment poll
minikube --profile="${profile_name}" kubectl -- get service poll
minikube --profile="${profile_name}" kubectl -- get ingress app-ingress
minikube --profile="${profile_name}" kubectl -- get pods -l app=poll
