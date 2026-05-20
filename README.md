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

### 1. 启动 MySQL

```bash
docker compose up -d
```

默认配置：

- 主机：`127.0.0.1:3306`
- 用户：`root`
- 密码：`password`
- 数据库：`shortlink`

### 2. 启动后端

```bash
cd backend
cp .env.example .env   # 按需修改数据库配置
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
| DB_PASSWORD | password | MySQL 密码 |
| DB_NAME | shortlink | 数据库名 |
| BASE_URL | http://localhost:8080 | 短链前缀 |

## Docker 部署（单容器：MySQL + 后端 + 前端）

所有服务打包在一个镜像 `shortlink:latest` 中，容器内通过 `127.0.0.1:3306` 连接 MySQL。

### 一键启动

```bash
cp .env.docker.example .env.docker   # 按需修改账号密码
docker compose up -d --build
```

访问：`BASE_URL` 配置的地址（默认 http://localhost）

### 环境变量（.env.docker）

| 变量 | 说明 |
|------|------|
| MYSQL_ROOT_PASSWORD | MySQL root 密码（必填） |
| MYSQL_DATABASE | 数据库名 |
| DB_USER | 后端连接用户，默认 `root` |
| DB_PASSWORD | 后端连接密码，**留空则自动使用 MYSQL_ROOT_PASSWORD** |
| DB_NAME | 后端连接数据库，**留空则自动使用 MYSQL_DATABASE** |
| BASE_URL | 短链前缀，需与对外访问域名一致 |
| APP_PORT | 对外 HTTP 端口，默认 80 |
| MYSQL_PORT | 对外 MySQL 端口，默认 3306 |

### 构建并导出单个 tar 镜像

```bash
chmod +x scripts/build-images.sh
./scripts/build-images.sh
```

生成：`docker-images/shortlink.tar`

### 在目标机器运行

```bash
docker load -i shortlink.tar

docker run -d --name shortlink \
  -p 8480:80 -p 8306:3306 \
  -e MYSQL_ROOT_PASSWORD=wz102411.. \
  -e MYSQL_DATABASE=urltolink \
  -e BASE_URL=https://link.arongwang.xyz \
  -v shortlink_mysql:/var/lib/mysql \
  shortlink:latest
```

> 数据持久化目录：`/var/lib/mysql`，建议挂载 volume。

## 技术栈

- **后端**：Go、Gin、GORM、MySQL
- **前端**：Vue 3、Vite、Axios
- **部署**：Docker（MariaDB + Nginx + Go 单容器）
