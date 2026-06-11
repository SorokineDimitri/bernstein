#!/usr/bin/env bash
set -euo pipefail

profile="bernstein"

echo "1. Wait for Kubernetes API"
until minikube --profile="${profile}" kubectl -- get nodes >/dev/null 2>&1; do
  echo "Kubernetes API is not ready yet; retrying..."
  sleep 5
done

echo "2. Wait for all nodes"
minikube --profile="${profile}" kubectl -- wait node --all --for=condition=Ready --timeout=300s

echo "3. Apply cAdvisor manifests"
minikube --profile="${profile}" kubectl -- apply -f utils/cadvisor/daemonset.yaml
minikube --profile="${profile}" kubectl -- apply -f utils/cadvisor/service.yaml

echo "4. Wait for cAdvisor rollout"
if ! minikube --profile="${profile}" kubectl -- rollout status daemonset/cadvisor -n kube-system --timeout=300s; then
  echo "cAdvisor rollout failed. Current state:"
  minikube --profile="${profile}" kubectl -- get pods -n kube-system -l app=cadvisor -o wide
  minikube --profile="${profile}" kubectl -- describe daemonset cadvisor -n kube-system
  exit 1
fi

echo "5. Show cAdvisor resources"
minikube --profile="${profile}" kubectl -- get daemonset cadvisor -n kube-system
minikube --profile="${profile}" kubectl -- get service cadvisor-service -n kube-system
minikube --profile="${profile}" kubectl -- get pods -n kube-system -l app=cadvisor -o wide
