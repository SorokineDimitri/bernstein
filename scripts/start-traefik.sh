#!/usr/bin/env bash
set -euo pipefail

profile="bernstein"

echo "1. Wait for Kubernetes API"
until minikube --profile="${profile}" kubectl -- get nodes >/dev/null 2>&1; do
  echo "Kubernetes API is not ready yet; retrying..."
  sleep 5
done

echo "2. Apply Traefik manifests"
minikube --profile="${profile}" kubectl -- apply -f utils/traefik/rbac.yaml
minikube --profile="${profile}" kubectl -- apply -f utils/traefik/service.yaml
minikube --profile="${profile}" kubectl -- delete statefulset traefik-statefulset -n kube-public --ignore-not-found
minikube --profile="${profile}" kubectl -- apply -f utils/traefik/deployment.yaml

echo "3. Wait for Traefik rollout"
minikube --profile="${profile}" kubectl -- rollout status deployment/traefik-deployment -n kube-public --timeout=180s

echo "4. Show Traefik resources"
minikube --profile="${profile}" kubectl -- get deployment traefik-deployment -n kube-public
minikube --profile="${profile}" kubectl -- get service traefik-service -n kube-public
minikube --profile="${profile}" kubectl -- get ingressclass traefik
minikube --profile="${profile}" kubectl -- get pods -n kube-public -l app=traefik
