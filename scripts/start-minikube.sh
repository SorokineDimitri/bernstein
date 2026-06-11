#!/usr/bin/env bash
set -euo pipefail

profile="bernstein"

minikube start \
  --profile="${profile}" \
  --driver=docker \
  --nodes=3 \
  --cpus=2 \
  --memory=2048

echo "Wait for all Minikube nodes"
minikube --profile="${profile}" kubectl -- wait node --all --for=condition=Ready --timeout=300s

minikube --profile="${profile}" kubectl -- get nodes
