#!/usr/bin/env bash
set -euo pipefail

profile="bernstein"
postgres_volume_path="/data/postgres"

if minikube --profile="${profile}" status >/dev/null 2>&1; then
  echo "1. Delete PostgreSQL Kubernetes objects"
  minikube --profile="${profile}" kubectl -- delete deployment postgres-deployment --ignore-not-found
  minikube --profile="${profile}" kubectl -- delete pvc postgres-claim --ignore-not-found
  minikube --profile="${profile}" kubectl -- delete pv postgres-volume --ignore-not-found

  echo "2. Delete PostgreSQL data from Minikube nodes"
  nodes="$(minikube --profile="${profile}" kubectl -- get nodes -o jsonpath='{.items[*].metadata.name}')"

  for node in ${nodes}; do
    minikube --profile="${profile}" ssh --node="${node}" -- "sudo rm -rf ${postgres_volume_path}"
  done
else
  echo "Minikube profile is not running; skipping PostgreSQL volume cleanup."
fi

echo "3. Delete Minikube profile"
minikube --profile="${profile}" delete

echo "Reset done."
