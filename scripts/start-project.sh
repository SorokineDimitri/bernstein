#!/usr/bin/env bash
set -euo pipefail

./scripts/start-minikube.sh
./scripts/start-cadvisor.sh
./scripts/start-redis.sh
./scripts/start-postgres.sh
./scripts/start-worker.sh
./scripts/start-traefik.sh
./scripts/start-poll.sh
./scripts/expose-services.sh
