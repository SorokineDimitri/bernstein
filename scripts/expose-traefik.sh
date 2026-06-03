#!/usr/bin/env bash
set -euo pipefail

profile="bernstein"

echo "1. Check Traefik service"
minikube --profile="${profile}" kubectl -- get service traefik-service -n kube-public

echo "2. Configure local hostnames"
if ! grep -q "poll.dop.io" /etc/hosts; then
  sudo sh -c 'echo "127.0.0.1 poll.dop.io result.dop.io" >> /etc/hosts'
fi

echo "3. Expose Traefik on localhost"
echo "Poll:      http://poll.dop.io:30021"
echo "Dashboard: http://localhost:30042/dashboard/"
echo
echo "Keep this terminal open. Stop with Ctrl+C."

minikube --profile="${profile}" kubectl -- port-forward \
  -n kube-public \
  service/traefik-service \
  30021:80 \
  30042:8080 &

port_forward_pid=$!
trap 'kill "${port_forward_pid}" >/dev/null 2>&1 || true' EXIT
echo
echo "4. Wait for Poll route"
ready_count=0

for _ in {1..60}; do
  status="$(curl -s -o /dev/null -w "%{http_code}" --resolve poll.dop.io:30021:127.0.0.1 http://poll.dop.io:30021/ || true)"

  if [[ "${status}" =~ ^[23] ]]; then
    ready_count=$((ready_count + 1))

    if (( ready_count == 5 )); then
      open "http://poll.dop.io:30021/"
      wait "${port_forward_pid}"
      exit 0
    fi
  else
    ready_count=0
  fi

  echo "Poll route is not stable yet; HTTP ${status}; retrying..."
  sleep 2
done

echo "Poll route did not become ready."
exit 1
