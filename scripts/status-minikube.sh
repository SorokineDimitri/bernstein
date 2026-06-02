#!/usr/bin/env bash
set -euo pipefail

profile="bernstein"

minikube --profile="${profile}" status || true

echo
minikube --profile="${profile}" kubectl -- get nodes || true
