#!/usr/bin/env bash
set -euo pipefail

profile="bernstein"

minikube start \
  --profile="${profile}" \
  --driver=docker \
  --nodes=3

minikube --profile="${profile}" kubectl -- get nodes
