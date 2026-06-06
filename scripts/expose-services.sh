#!/usr/bin/env bash
set -euo pipefail

profile="bernstein"
pids=()

cleanup() {
  for pid in "${pids[@]}"; do
    kill "${pid}" >/dev/null 2>&1 || true
  done
}

wait_for_url() {
  local name="$1"
  local url="$2"
  local status
  shift 2

  for attempt in {1..60}; do
    status="$(curl -s -o /dev/null -w "%{http_code}" "$@" "${url}" || true)"

    if [[ "${status}" =~ ^[23] ]]; then
      return 0
    fi

    if (( attempt > 3 )); then
      echo "${name} is not ready yet; HTTP ${status}; retrying..."
    fi

    sleep 2
  done

  echo "${name} did not become ready."
  return 1
}

trap cleanup EXIT

echo "1. Check services"
minikube --profile="${profile}" kubectl -- get service traefik-service -n kube-public
minikube --profile="${profile}" kubectl -- get service cadvisor-service -n kube-system

echo "2. Configure local hostnames"
if ! grep -q "poll.dop.io" /etc/hosts; then
  sudo sh -c 'echo "127.0.0.1 poll.dop.io result.dop.io" >> /etc/hosts'
fi

echo "3. Expose Poll and cAdvisor"
echo "Poll:     http://poll.dop.io:30021"
echo "cAdvisor: http://localhost:8080"
echo
echo "Keep this terminal open. Stop with Ctrl+C."

minikube --profile="${profile}" kubectl -- port-forward \
  -n kube-public \
  service/traefik-service \
  30021:80 >/dev/null &
pids+=("$!")

minikube --profile="${profile}" kubectl -- port-forward \
  -n kube-system \
  service/cadvisor-service \
  8080:8080 >/dev/null &
pids+=("$!")

echo
echo "4. Wait for routes"
sleep 1
wait_for_url "Poll" "http://poll.dop.io:30021/" --resolve "poll.dop.io:30021:127.0.0.1"
wait_for_url "cAdvisor" "http://localhost:8080/"

open "http://poll.dop.io:30021/"
open "http://localhost:8080/"

wait
