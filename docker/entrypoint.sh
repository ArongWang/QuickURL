#!/bin/bash
set -euo pipefail

DB_HOST="${DB_HOST:?DB_HOST is required}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:?DB_USER is required}"
DB_PASSWORD="${DB_PASSWORD:?DB_PASSWORD is required}"
DB_NAME="${DB_NAME:?DB_NAME is required}"
SERVER_PORT="${SERVER_PORT:-8080}"
BASE_URL="${BASE_URL:-http://localhost}"

export DB_HOST DB_PORT DB_USER DB_PASSWORD DB_NAME SERVER_PORT BASE_URL

wait_for_db_port() {
  echo "Waiting for MySQL at ${DB_HOST}:${DB_PORT} ..."
  for _ in $(seq 1 60); do
    if (echo >/dev/tcp/"${DB_HOST}"/"${DB_PORT}") 2>/dev/null; then
      echo "MySQL port is reachable"
      return 0
    fi
    sleep 1
  done
  echo "Cannot reach MySQL at ${DB_HOST}:${DB_PORT} (timeout 60s)"
  return 1
}

start_backend() {
  echo "Starting backend (DB=${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME})..."
  /app/server &
  BACKEND_PID=$!
}

start_nginx() {
  echo "Starting Nginx..."
  nginx -g "daemon off;" &
  NGINX_PID=$!
}

shutdown() {
  echo "Shutting down..."
  [ -n "${NGINX_PID:-}" ] && kill "${NGINX_PID}" 2>/dev/null || true
  [ -n "${BACKEND_PID:-}" ] && kill "${BACKEND_PID}" 2>/dev/null || true
  exit 0
}

trap shutdown SIGTERM SIGINT

wait_for_db_port
start_backend
start_nginx

wait -n "${BACKEND_PID}" "${NGINX_PID}"
