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

ENV DB_HOST= \
    DB_PORT=3306 \
    DB_USER= \
    DB_PASSWORD= \
    DB_NAME= \
    SERVER_PORT=8080 \
    BASE_URL=http://localhost

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/sites-enabled/default

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/entrypoint.sh /entrypoint.sh

COPY --from=backend-builder /build/server /app/server
COPY --from=frontend-builder /build/dist /usr/share/nginx/html

RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
