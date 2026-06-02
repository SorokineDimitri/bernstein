#!/usr/bin/env bash
set -euo pipefail

container_name="bernstein-minikube"
image_name="bernstein-minikube"

echo "1. Build Minikube image"
docker build -t bernstein-minikube .

echo "2. Remove old container if it exists"
docker rm -f "${container_name}" >/dev/null 2>&1 || true

echo "3. Start container in detached mode"
docker run -d --privileged \
  --name "${container_name}" \
  -v "$PWD:/bernstein" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v bernstein-minikube:/root/.minikube \
  -v bernstein-kube:/root/.kube \
  "${image_name}" \
  sleep infinity

echo "4. Container is running"
docker ps --filter "name=${container_name}"

echo
echo "Open a shell:"
echo "docker exec -it ${container_name} bash"
echo
echo "Stop the container:"
echo "docker stop ${container_name}"
