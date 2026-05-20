FROM golang:1.25-alpine AS backend-builder

WORKDIR /build

RUN apk add --no-cache git ca-certificates

COPY backend/go.mod backend/go.sum ./
RUN go mod download

COPY backend/ ./
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server .

FROM node:20-alpine AS frontend-builder

WORKDIR /build

COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

COPY frontend/ ./
RUN npm run build

FROM debian:bookworm-slim

ENV MYSQL_ROOT_PASSWORD=password \
    MYSQL_DATABASE=shortlink \
    DB_USER=root \
    DB_PASSWORD=password \
    DB_NAME=shortlink \
    DB_HOST=127.0.0.1 \
    DB_PORT=3306 \
    SERVER_PORT=8080 \
    BASE_URL=http://localhost

RUN apt-get update && apt-get install -y --no-install-recommends \
    mariadb-server \
    nginx \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/sites-enabled/default

COPY docker/my.cnf /etc/mysql/mariadb.conf.d/99-shortlink.cnf
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/entrypoint.sh /entrypoint.sh

COPY --from=backend-builder /build/server /app/server
COPY --from=frontend-builder /build/dist /usr/share/nginx/html

RUN chmod +x /entrypoint.sh \
    && mkdir -p /var/run/mysqld \
    && chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

VOLUME ["/var/lib/mysql"]

EXPOSE 80 3306

ENTRYPOINT ["/entrypoint.sh"]
