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

## Docker 部署

### 一键启动（构建并运行）

```bash
cp .env.docker.example .env.docker   # 按需修改
docker compose --env-file .env.docker up -d --build
```

访问：http://localhost

- 前端页面：`/`
- API 接口：`/api/*`
- 短链跳转：`/{6位短码}`（经 Nginx 转发到后端）

### 仅构建镜像

```bash
docker compose build
```

构建完成后本地镜像：

- `shortlink-backend:latest`
- `shortlink-frontend:latest`

### 导出镜像文件（tar）

```bash
chmod +x scripts/build-images.sh
./scripts/build-images.sh
```

会在 `docker-images/` 目录生成：

- `shortlink-backend.tar`
- `shortlink-frontend.tar`

在目标机器导入：

```bash
docker load -i shortlink-backend.tar
docker load -i shortlink-frontend.tar
```

### Docker 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| MYSQL_ROOT_PASSWORD | password | MySQL root 密码 |
| MYSQL_DATABASE | shortlink | 数据库名 |
| MYSQL_PORT | 3306 | MySQL 对外端口 |
| APP_PORT | 80 | 前端对外端口 |
| BASE_URL | http://localhost | 短链前缀（需与对外访问地址一致） |

## 技术栈

- **后端**：Go、Gin、GORM、MySQL
- **前端**：Vue 3、Vite、Axios
- **部署**：Docker、Nginx
