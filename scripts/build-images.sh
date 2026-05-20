#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${ROOT_DIR}/docker-images"

mkdir -p "${OUTPUT_DIR}"

echo "==> Building images with docker compose..."
export BUILDX_NO_DEFAULT_ATTESTATIONS=1
docker compose -f "${ROOT_DIR}/docker-compose.yml" build

echo "==> Saving images to ${OUTPUT_DIR}..."
docker save shortlink-backend:latest -o "${OUTPUT_DIR}/shortlink-backend.tar"
docker save shortlink-frontend:latest -o "${OUTPUT_DIR}/shortlink-frontend.tar"

echo "Done."
echo "  ${OUTPUT_DIR}/shortlink-backend.tar"
echo "  ${OUTPUT_DIR}/shortlink-frontend.tar"
echo ""
echo "Load on another machine:"
echo "  docker load -i shortlink-backend.tar"
echo "  docker load -i shortlink-frontend.tar"
