#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${ROOT_DIR}/docker-images"

mkdir -p "${OUTPUT_DIR}"

echo "==> Building image for linux/amd64 (typical Linux servers)..."
export BUILDX_NO_DEFAULT_ATTESTATIONS=1
export DOCKER_DEFAULT_PLATFORM=linux/amd64
docker compose -f "${ROOT_DIR}/docker-compose.yml" build

echo "==> Saving image to ${OUTPUT_DIR}/shortlink.tar ..."
docker save shortlink:latest -o "${OUTPUT_DIR}/shortlink.tar"

echo "Done."
echo "  ${OUTPUT_DIR}/shortlink.tar"
echo ""
echo "Load on another machine:"
echo "  docker load -i shortlink.tar"
echo ""
echo "Run (use your external MySQL):"
echo "  docker run -d --name shortlink \\"
echo "    -p 80:80 \\"
echo "    -e DB_HOST=your-mysql-host \\"
echo "    -e DB_PORT=3306 \\"
echo "    -e DB_USER=root \\"
echo "    -e DB_PASSWORD=your_password \\"
echo "    -e DB_NAME=shortlink \\"
echo "    -e BASE_URL=https://your-domain.com \\"
echo "    shortlink:latest"
