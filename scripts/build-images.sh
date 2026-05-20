#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${ROOT_DIR}/docker-images"

mkdir -p "${OUTPUT_DIR}"

echo "==> Building all-in-one image for linux/amd64 (typical Linux servers)..."
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
echo "Run:"
echo "  docker run -d --name shortlink \\"
echo "    -p 80:80 -p 3306:3306 \\"
echo "    -e MYSQL_ROOT_PASSWORD=your_password \\"
echo "    -e MYSQL_DATABASE=urltolink \\"
echo "    -e DB_PASSWORD=your_password \\"
echo "    -e DB_NAME=urltolink \\"
echo "    -e BASE_URL=https://your-domain.com \\"
echo "    -v shortlink_mysql:/var/lib/mysql \\"
echo "    shortlink:latest"
