# 短链接生成器

Go 后端 + Vue 前端 + MySQL 的短链接服务。

## 项目结构

```
.
├── backend/          # Go API 服务
├── frontend/         # Vue 3 前端
└── docker-compose.yml
```

## 快速开始

### 1. 准备 MySQL

自行安装或使用已有的 MySQL / MariaDB，创建数据库（表结构由后端启动时自动迁移）。

### 2. 启动后端

```bash
cd backend
cp .env.example .env   # 填写 DB_HOST、DB_USER、DB_PASSWORD、DB_NAME 等
go mod tidy
go run .
```

后端默认监听 `http://localhost:8080`。

### 3. 启动前端

```bash
cd frontend
npm install
npm run dev
```

前端默认访问 `http://localhost:5173`，API 请求会通过 Vite 代理转发到后端。

## API 接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/health` | 健康检查 |
| POST | `/api/links` | 创建短链接，body: `{ "url": "https://..." }` |
| GET | `/api/links` | 获取链接列表 |
| GET | `/:code` | 短链跳转 |

## 环境变量

参考 `backend/.env.example`：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| SERVER_PORT | 8080 | 服务端口 |
| DB_HOST | 127.0.0.1 | MySQL 主机 |
| DB_PORT | 3306 | MySQL 端口 |
| DB_USER | root | MySQL 用户 |
| DB_PASSWORD | （空） | MySQL 密码 |
| DB_NAME | shortlink | 数据库名 |
| BASE_URL | http://localhost:8080 | 短链前缀 |

## Docker 部署（Nginx + 后端，外接 MySQL）

镜像内**不包含数据库**，启动时必须提供外部 MySQL 连接信息。

### 一键启动

```bash
cp .env.docker.example .env.docker
# 编辑 .env.docker，填写 DB_HOST、DB_PORT、DB_USER、DB_PASSWORD、DB_NAME
docker compose up -d --build
```

访问：`BASE_URL` 配置的地址（默认 http://localhost，映射端口见 `APP_PORT`）

### 环境变量（.env.docker 或 docker run -e）

| 变量 | 必填 | 说明 |
|------|------|------|
| DB_HOST | 是 | MySQL 地址（IP 或域名） |
| DB_PORT | 否 | MySQL 端口，默认 `3306` |
| DB_USER | 是 | MySQL 用户名 |
| DB_PASSWORD | 是 | MySQL 密码 |
| DB_NAME | 是 | 数据库名 |
| BASE_URL | 否 | 短链前缀，需与对外访问域名一致 |
| APP_PORT | 否 | 宿主机 HTTP 端口，默认 `80` |

> 容器需能访问 `DB_HOST:DB_PORT`（云数据库请放行该容器/服务器 IP）。

### 构建并导出 tar 镜像

```bash
chmod +x scripts/build-images.sh
./scripts/build-images.sh
```

生成：`docker-images/shortlink.tar`

### 在目标机器运行

```bash
docker load -i shortlink.tar

docker run -d --name shortlink \
  -p 8480:80 \
  -e DB_HOST=127.0.0.1 \
  -e DB_PORT=3306 \
  -e DB_USER=root \
  -e DB_PASSWORD='your_password' \
  -e DB_NAME=urltolink \
  -e BASE_URL=https://demon.com \
  shortlink:latest
```

浏览器访问：`http://服务器IP:8480`（`-p` 左边为宿主机端口）

### 常见问题：`exec format error`

在 Mac（Apple Silicon）上构建、在 x86 Linux 上运行时，请用项目脚本或 `DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose build` 重新打包。

## 技术栈

- **后端**：Go、Gin、GORM、MySQL
- **前端**：Vue 3、Vite、Axios
- **部署**：Docker（Nginx + Go，外接 MySQL）
