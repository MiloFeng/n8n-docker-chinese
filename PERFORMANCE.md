# n8n 性能优化指南

本文档提供 n8n Docker 部署的性能优化建议和最佳实践。

## 📊 性能监控

### 基础监控

```bash
# 查看容器资源使用情况
docker stats

# 持续监控
docker stats --no-stream

# 查看特定容器
docker stats n8n n8n-postgres
```

### 详细监控

```bash
# 查看 n8n 内存使用
docker compose exec n8n sh -c 'ps aux | grep node'

# 查看数据库大小
docker compose exec postgres psql -U n8n n8n -c "
SELECT 
    pg_size_pretty(pg_database_size('n8n')) as db_size,
    pg_size_pretty(pg_total_relation_size('execution_entity')) as executions_size;
"

# 查看执行记录数量
docker compose exec postgres psql -U n8n n8n -c "
SELECT COUNT(*) FROM execution_entity;
"
```

## 🚀 Docker 资源优化

### 设置资源限制

编辑 `docker-compose.yml`,添加资源限制:

```yaml
services:
  n8n:
    deploy:
      resources:
        limits:
          cpus: '2'        # 最大使用 2 个 CPU 核心
          memory: 2G       # 最大使用 2GB 内存
        reservations:
          cpus: '1'        # 保留 1 个 CPU 核心
          memory: 1G       # 保留 1GB 内存
  
  postgres:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

### 优化 Docker 存储驱动

```bash
# 查看当前存储驱动
docker info | grep "Storage Driver"

# 推荐使用 overlay2
# 编辑 /etc/docker/daemon.json
{
  "storage-driver": "overlay2"
}

# 重启 Docker
sudo systemctl restart docker
```

## 🗄️ 数据库优化

### PostgreSQL 优化

#### 1. 调整 PostgreSQL 配置

创建 `postgres/postgresql.conf`:
```conf
# 内存设置
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
work_mem = 16MB

# 连接设置
max_connections = 100

# 查询优化
random_page_cost = 1.1
effective_io_concurrency = 200

# WAL 设置
wal_buffers = 16MB
min_wal_size = 1GB
max_wal_size = 4GB

# 检查点设置
checkpoint_completion_target = 0.9
```

在 `docker-compose.yml` 中挂载配置:
```yaml
postgres:
  volumes:
    - postgres_data:/var/lib/postgresql/data
    - ./postgres/postgresql.conf:/etc/postgresql/postgresql.conf
  command: postgres -c config_file=/etc/postgresql/postgresql.conf
```

#### 2. 定期清理执行记录

创建 `scripts/cleanup-executions.sh`:
```bash
#!/bin/bash

# 清理 30 天前的执行记录
docker compose exec -T postgres psql -U n8n n8n <<EOF
DELETE FROM execution_entity 
WHERE "startedAt" < NOW() - INTERVAL '30 days';

VACUUM ANALYZE execution_entity;
EOF

echo "执行记录清理完成"
```

```bash
chmod +x scripts/cleanup-executions.sh

# 添加到 crontab (每周执行)
0 2 * * 0 /path/to/n8n/scripts/cleanup-executions.sh
```

#### 3. 优化索引

```bash
# 进入数据库
docker compose exec postgres psql -U n8n n8n

# 创建索引
CREATE INDEX IF NOT EXISTS idx_execution_started_at 
ON execution_entity("startedAt");

CREATE INDEX IF NOT EXISTS idx_execution_workflow_id 
ON execution_entity("workflowId");

# 分析表
ANALYZE execution_entity;
```

### MySQL 优化

编辑 `docker-compose.mysql.yml`,添加 MySQL 配置:
```yaml
mysql:
  command: 
    - --default-authentication-plugin=mysql_native_password
    - --max_connections=200
    - --innodb_buffer_pool_size=512M
    - --innodb_log_file_size=128M
    - --query_cache_size=0
    - --query_cache_type=0
```

## ⚙️ n8n 配置优化

### 执行模式优化

在 `.env` 中配置:

```bash
# 执行模式 (main 或 queue)
EXECUTIONS_PROCESS=main
EXECUTIONS_MODE=regular

# 对于高负载场景,使用队列模式
# EXECUTIONS_PROCESS=queue
# QUEUE_BULL_REDIS_HOST=redis
# QUEUE_BULL_REDIS_PORT=6379
```

### 超时设置

```bash
# 执行超时时间 (秒)
EXECUTIONS_TIMEOUT=300
EXECUTIONS_TIMEOUT_MAX=3600

# 数据保存设置
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
```

### 数据保留策略

```bash
# 启用自动清理
EXECUTIONS_DATA_PRUNE=true

# 保留天数
EXECUTIONS_DATA_MAX_AGE=168  # 7天

# 清理间隔 (小时)
EXECUTIONS_DATA_PRUNE_TIMEOUT=1
```

### 并发限制

```bash
# 生产环境并发限制
N8N_CONCURRENCY_PRODUCTION_LIMIT=10

# 工作流并发限制
EXECUTIONS_CONCURRENCY_MAX=50
```

## 🔄 使用 Redis 队列模式

对于高负载场景,推荐使用 Redis 队列模式。

### 添加 Redis 服务

编辑 `docker-compose.yml`:
```yaml
services:
  redis:
    image: redis:7-alpine
    container_name: n8n-redis
    restart: unless-stopped
    volumes:
      - redis_data:/data
    networks:
      - n8n-network
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 5s
      timeout: 5s
      retries: 5

  n8n:
    environment:
      # 启用队列模式
      - EXECUTIONS_PROCESS=queue
      - QUEUE_BULL_REDIS_HOST=redis
      - QUEUE_BULL_REDIS_PORT=6379
      - QUEUE_BULL_REDIS_DB=0
    depends_on:
      - redis

volumes:
  redis_data:
    driver: local
```

## 📈 工作流优化建议

### 1. 减少不必要的执行

```bash
# 只保存错误执行
EXECUTIONS_DATA_SAVE_ON_SUCCESS=none
EXECUTIONS_DATA_SAVE_ON_ERROR=all
```

### 2. 使用批处理

- 合并多个小任务为批处理任务
- 使用 Split In Batches 节点处理大数据集

### 3. 优化轮询间隔

- 避免过于频繁的轮询
- 使用 Webhook 替代轮询

### 4. 缓存策略

- 使用 Function 节点缓存常用数据
- 利用 Redis 存储临时数据

## 🌐 网络优化

### 使用 CDN

对于静态资源,考虑使用 CDN:
```nginx
# nginx.conf
location /static/ {
    proxy_cache my_cache;
    proxy_cache_valid 200 1d;
    proxy_pass http://n8n:5678;
}
```

### 启用 Gzip 压缩

在 `nginx/nginx.conf` 中添加:
```nginx
http {
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript;
}
```

## 💾 存储优化

### 使用 SSD

确保 Docker 数据目录在 SSD 上:
```bash
# 查看 Docker 数据目录
docker info | grep "Docker Root Dir"

# 如需迁移,编辑 /etc/docker/daemon.json
{
  "data-root": "/path/to/ssd/docker"
}
```

### 定期清理

```bash
# 清理未使用的镜像
docker image prune -a

# 清理未使用的卷
docker volume prune

# 完整清理
docker system prune -a --volumes
```

## 📊 性能基准测试

### 测试数据库性能

```bash
# PostgreSQL 性能测试
docker compose exec postgres pgbench -i -s 10 n8n
docker compose exec postgres pgbench -c 10 -j 2 -t 1000 n8n
```

### 测试 n8n 响应时间

```bash
# 使用 Apache Bench
ab -n 1000 -c 10 http://localhost:5678/

# 使用 curl 测试
time curl http://localhost:5678/
```

## 🔍 性能问题诊断

### 识别慢查询

```bash
# PostgreSQL 慢查询日志
docker compose exec postgres psql -U n8n n8n -c "
SELECT 
    query,
    calls,
    total_time,
    mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
"
```

### 分析容器性能

```bash
# 使用 ctop (需要安装)
brew install ctop  # macOS
ctop

# 或使用 docker stats
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

## 📝 性能优化检查清单

- [ ] 设置合理的资源限制
- [ ] 配置数据库连接池
- [ ] 启用执行记录自动清理
- [ ] 优化数据库索引
- [ ] 使用 Redis 队列模式 (高负载)
- [ ] 配置合理的超时时间
- [ ] 启用 Gzip 压缩
- [ ] 使用 SSD 存储
- [ ] 定期备份和清理
- [ ] 监控资源使用情况

## 🎯 推荐配置

### 小型部署 (< 10 个工作流)

```bash
# Docker 资源
n8n: 1 CPU, 1GB RAM
postgres: 0.5 CPU, 512MB RAM

# n8n 配置
EXECUTIONS_DATA_MAX_AGE=168  # 7天
N8N_CONCURRENCY_PRODUCTION_LIMIT=5
```

### 中型部署 (10-50 个工作流)

```bash
# Docker 资源
n8n: 2 CPU, 2GB RAM
postgres: 1 CPU, 1GB RAM

# n8n 配置
EXECUTIONS_DATA_MAX_AGE=336  # 14天
N8N_CONCURRENCY_PRODUCTION_LIMIT=10
EXECUTIONS_PROCESS=queue  # 使用 Redis
```

### 大型部署 (> 50 个工作流)

```bash
# Docker 资源
n8n: 4 CPU, 4GB RAM
postgres: 2 CPU, 2GB RAM
redis: 1 CPU, 1GB RAM

# n8n 配置
EXECUTIONS_DATA_MAX_AGE=720  # 30天
N8N_CONCURRENCY_PRODUCTION_LIMIT=20
EXECUTIONS_PROCESS=queue
```

---

**提示**: 性能优化是一个持续的过程,需要根据实际使用情况不断调整。

