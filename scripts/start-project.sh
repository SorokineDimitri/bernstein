#!/usr/bin/env bash
set -euo pipefail

./scripts/start-minikube.sh
./scripts/start-redis.sh
./scripts/start-postgres.sh
./scripts/start-traefik.sh
./scripts/start-poll.sh
./scripts/expose-traefik.sh
