#!/bin/bash
set -euo pipefail

MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"
MYSQL_DATABASE="${MYSQL_DATABASE:-shortlink}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-}"
DB_NAME="${DB_NAME:-}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
SERVER_PORT="${SERVER_PORT:-8080}"
BASE_URL="${BASE_URL:-http://localhost}"

if [ -z "${DB_PASSWORD}" ]; then
  DB_PASSWORD="${MYSQL_ROOT_PASSWORD}"
fi
if [ -z "${DB_NAME}" ]; then
  DB_NAME="${MYSQL_DATABASE}"
fi

export DB_HOST DB_PORT DB_USER DB_PASSWORD DB_NAME SERVER_PORT BASE_URL

wait_for_mysql() {
  local user="$1"
  local password="$2"
  for _ in $(seq 1 60); do
    if mysqladmin ping -h127.0.0.1 -u"${user}" -p"${password}" --silent 2>/dev/null; then
      return 0
    fi
    sleep 1
  done
  echo "MariaDB failed to start"
  return 1
}

initialize_mysql() {
  if [ -d "/var/lib/mysql/mysql" ]; then
    return 0
  fi

  echo "Initializing MariaDB data directory..."
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql --auth-root-authentication-method=normal

  mysqld_safe --datadir=/var/lib/mysql --skip-networking &
  local mysqld_pid=$!

  for _ in $(seq 1 60); do
    if mysqladmin ping --silent 2>/dev/null; then
      break
    fi
    sleep 1
  done

  mysql -uroot <<-EOSQL
	ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
	CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
	FLUSH PRIVILEGES;
EOSQL

  mysqladmin shutdown -uroot -p"${MYSQL_ROOT_PASSWORD}" || kill "${mysqld_pid}" 2>/dev/null || true
  wait "${mysqld_pid}" 2>/dev/null || true
}

start_mysql() {
  echo "Starting MariaDB..."
  mysqld_safe --datadir=/var/lib/mysql &
  wait_for_mysql "${DB_USER}" "${DB_PASSWORD}"
}

ensure_database() {
  mysql -h127.0.0.1 -u"${DB_USER}" -p"${DB_PASSWORD}" <<-EOSQL
	CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOSQL
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
  mysqladmin shutdown -h127.0.0.1 -u"${DB_USER}" -p"${DB_PASSWORD}" 2>/dev/null || true
  exit 0
}

trap shutdown SIGTERM SIGINT

initialize_mysql
start_mysql
ensure_database
start_backend
start_nginx

wait -n "${BACKEND_PID}" "${NGINX_PID}"
