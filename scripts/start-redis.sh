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

echo "2. Apply Redis manifests"
minikube --profile="${profile_name}" kubectl -- apply -f db/redis/configmap.yaml
minikube --profile="${profile_name}" kubectl -- apply -f db/redis/service.yaml
minikube --profile="${profile_name}" kubectl -- delete deployment redis-deployment --ignore-not-found
minikube --profile="${profile_name}" kubectl -- apply -f db/redis/statefulset.yaml

echo "3. Wait for Redis rollout"
minikube --profile="${profile_name}" kubectl -- rollout status statefulset/redis-statefulset --timeout=180s

echo "4. Show Redis resources"
minikube --profile="${profile_name}" kubectl -- get configmap redis-configmap
minikube --profile="${profile_name}" kubectl -- get statefulset redis-statefulset
minikube --profile="${profile_name}" kubectl -- get service redis-service
minikube --profile="${profile_name}" kubectl -- get pods -l app=redis
