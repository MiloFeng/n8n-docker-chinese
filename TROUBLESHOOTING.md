# n8n 故障排查指南

本文档提供常见问题的解决方案和调试技巧。

## 📋 目录

- [服务启动问题](#服务启动问题)
- [数据库连接问题](#数据库连接问题)
- [网络和端口问题](#网络和端口问题)
- [性能问题](#性能问题)
- [数据问题](#数据问题)
- [Webhook 问题](#webhook-问题)
- [SSL/HTTPS 问题](#sslhttps-问题)
- [警告信息说明](#警告信息说明)

## 🔧 服务启动问题

### 问题: 容器无法启动

**症状**: 运行 `docker compose up -d` 后容器立即退出

**诊断步骤**:
```bash
# 1. 查看容器状态
docker compose ps

# 2. 查看详细日志
docker compose logs -f

# 3. 检查特定容器日志
docker compose logs n8n
docker compose logs postgres
```

**常见原因和解决方案**:

#### 原因 1: 端口冲突
```bash
# 检查端口占用
lsof -i :5678
# 或
netstat -an | grep 5678

# 解决方案 1: 停止占用端口的进程
kill -9 <PID>

# 解决方案 2: 修改端口
# 编辑 docker-compose.yml
ports:
  - "8080:5678"  # 改为其他端口
```

#### 原因 2: 磁盘空间不足
```bash
# 检查磁盘空间
df -h

# 清理 Docker 资源
docker system prune -a
docker volume prune
```

#### 原因 3: 权限问题
```bash
# 检查文件权限
ls -la

# 修复权限
sudo chown -R $USER:$USER .
chmod +x scripts/*.sh
```

### 问题: 容器频繁重启

**症状**: 容器状态显示 "Restarting"

**诊断**:
```bash
# 查看重启次数
docker compose ps

# 查看最近的日志
docker compose logs --tail=100 n8n
```

**解决方案**:
```bash
# 1. 检查环境变量配置
cat .env

# 2. 验证数据库连接
docker compose exec postgres pg_isready -U n8n

# 3. 重新创建容器
docker compose down
docker compose up -d
```

## 🗄️ 数据库连接问题

### 问题: n8n 无法连接到 PostgreSQL

**症状**: 日志显示 "Connection refused" 或 "ECONNREFUSED"

**诊断步骤**:
```bash
# 1. 检查 PostgreSQL 容器状态
docker compose ps postgres

# 2. 检查 PostgreSQL 健康状态
docker compose exec postgres pg_isready -U n8n -d n8n

# 3. 查看 PostgreSQL 日志
docker compose logs postgres
```

**解决方案**:

#### 方案 1: 等待数据库就绪
```bash
# PostgreSQL 可能需要时间初始化
# 等待 30 秒后重启 n8n
sleep 30
docker compose restart n8n
```

#### 方案 2: 检查数据库配置
```bash
# 验证 .env 文件中的数据库配置
cat .env | grep DB_

# 确保以下配置正确:
# DB_TYPE=postgresdb
# DB_POSTGRESDB_HOST=postgres
# DB_POSTGRESDB_PORT=5432
# DB_POSTGRESDB_DATABASE=n8n
# DB_POSTGRESDB_USER=n8n
# DB_POSTGRESDB_PASSWORD=n8n_password
```

#### 方案 3: 重置数据库
```bash
# 警告: 这将删除所有数据!
docker compose down -v
docker compose up -d
```

### 问题: 数据库密码错误

**症状**: 日志显示 "password authentication failed"

**解决方案**:
```bash
# 1. 停止服务
docker compose down

# 2. 删除数据库卷
docker volume rm n8n_postgres_data

# 3. 确保 .env 中的密码一致
# POSTGRES_PASSWORD 和 DB_POSTGRESDB_PASSWORD 必须相同

# 4. 重新启动
docker compose up -d
```

## 🌐 网络和端口问题

### 问题: 无法访问 Web 界面

**症状**: 浏览器无法打开 http://localhost:5678

**诊断步骤**:
```bash
# 1. 检查服务是否运行
docker compose ps

# 2. 检查端口映射
docker compose port n8n 5678

# 3. 测试本地连接
curl http://localhost:5678
```

**解决方案**:

#### 方案 1: 检查防火墙
```bash
# macOS
sudo pfctl -d  # 临时禁用防火墙测试

# Linux (Ubuntu)
sudo ufw status
sudo ufw allow 5678

# 检查 iptables
sudo iptables -L -n
```

#### 方案 2: 检查 Docker 网络
```bash
# 查看网络配置
docker network ls
docker network inspect n8n_n8n-network

# 重新创建网络
docker compose down
docker compose up -d
```

### 问题: 外网无法访问

**症状**: 本地可以访问,但外网无法访问

**解决方案**:
```bash
# 1. 确保服务器防火墙开放端口
sudo ufw allow 5678

# 2. 检查云服务商安全组规则
# AWS: Security Groups
# 阿里云: 安全组规则
# 腾讯云: 安全组

# 3. 配置正确的 WEBHOOK_URL
# 在 .env 中设置:
WEBHOOK_URL=http://your-public-ip:5678/
```

## ⚡ 性能问题

### 问题: n8n 响应缓慢

**诊断**:
```bash
# 查看资源使用情况
docker stats

# 查看容器日志
docker compose logs --tail=100 n8n
```

**解决方案**:

#### 方案 1: 增加资源限制
编辑 `docker-compose.yml`:
```yaml
services:
  n8n:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

#### 方案 2: 优化数据库
```bash
# 清理旧的执行记录
docker compose exec postgres psql -U n8n n8n -c "
DELETE FROM execution_entity 
WHERE \"startedAt\" < NOW() - INTERVAL '30 days';
"

# 或在 .env 中配置自动清理
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=168  # 7天
```

#### 方案 3: 使用外部数据库
如果数据量大,考虑使用独立的 PostgreSQL 服务器。

### 问题: 工作流执行超时

**解决方案**:
在 `.env` 中增加超时时间:
```bash
EXECUTIONS_TIMEOUT=600  # 10分钟
EXECUTIONS_TIMEOUT_MAX=3600  # 1小时
```

## 💾 数据问题

### 问题: 数据丢失

**预防措施**:
```bash
# 1. 定期备份
# 添加到 crontab
crontab -e

# 每天凌晨 2 点备份
0 2 * * * cd /path/to/n8n && ./scripts/backup.sh

# 2. 验证数据卷
docker volume ls | grep n8n
docker volume inspect n8n_n8n_data
```

**恢复数据**:
```bash
# 从备份恢复
./scripts/restore.sh 20240115-120000
```

### 问题: 工作流无法保存

**症状**: 保存工作流时出错

**解决方案**:
```bash
# 1. 检查磁盘空间
df -h

# 2. 检查数据卷权限
docker volume inspect n8n_n8n_data

# 3. 检查数据库连接
docker compose logs n8n | grep -i error

# 4. 重启服务
docker compose restart n8n
```

## 🔗 Webhook 问题

### 问题: Webhook 无法触发

**诊断**:
```bash
# 1. 检查 WEBHOOK_URL 配置
docker compose exec n8n env | grep WEBHOOK

# 2. 测试 Webhook
curl -X POST http://localhost:5678/webhook-test/your-webhook-id
```

**解决方案**:

#### 方案 1: 配置正确的 Webhook URL
```bash
# 本地开发
WEBHOOK_URL=http://localhost:5678/

# 生产环境
WEBHOOK_URL=https://n8n.yourdomain.com/
```

#### 方案 2: 使用 ngrok 进行本地测试
```bash
# 安装 ngrok
brew install ngrok  # macOS
# 或从 https://ngrok.com/ 下载

# 启动 ngrok
ngrok http 5678

# 在 .env 中设置 ngrok URL
WEBHOOK_URL=https://your-ngrok-url.ngrok.io/
```

## 🔐 SSL/HTTPS 问题

### 问题: SSL 证书错误

**症状**: 浏览器显示证书不受信任

**解决方案**:

#### 开发环境 (自签名证书)
```bash
# 浏览器中添加例外
# Chrome: 点击 "高级" -> "继续访问"
# Firefox: 点击 "高级" -> "添加例外"
```

#### 生产环境 (Let's Encrypt)
```bash
# 1. 安装 certbot
sudo apt-get install certbot

# 2. 生成证书
sudo certbot certonly --standalone -d n8n.yourdomain.com

# 3. 复制证书
sudo cp /etc/letsencrypt/live/n8n.yourdomain.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/n8n.yourdomain.com/privkey.pem nginx/ssl/key.pem

# 4. 设置自动续期
sudo certbot renew --dry-run
```

### 问题: HTTPS 重定向循环

**症状**: 页面不断重定向

**解决方案**:
检查 `nginx/nginx.conf` 配置:
```nginx
# 确保正确设置代理头
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

## 🔍 调试技巧

### 启用调试日志

在 `.env` 中设置:
```bash
N8N_LOG_LEVEL=debug
```

重启服务:
```bash
docker compose restart n8n
```

### 进入容器调试

```bash
# 进入 n8n 容器
docker compose exec n8n sh

# 进入数据库容器
docker compose exec postgres psql -U n8n n8n

# 查看 n8n 配置
docker compose exec n8n env
```

### 网络调试

```bash
# 测试容器间网络
docker compose exec n8n ping postgres

# 测试外部网络
docker compose exec n8n ping google.com

# 查看网络配置
docker network inspect n8n_n8n-network
```

## 📞 获取帮助

如果以上方法都无法解决问题:

1. **查看日志**: `docker compose logs -f`
2. **搜索社区**: [n8n Community](https://community.n8n.io/)
3. **GitHub Issues**: [n8n GitHub](https://github.com/n8n-io/n8n/issues)
4. **官方文档**: [n8n Documentation](https://docs.n8n.io/)

## 🛠️ 常用诊断命令

```bash
# 完整健康检查
docker compose ps
docker compose logs --tail=50
docker stats --no-stream
df -h
docker volume ls
docker network ls

# 重置服务 (保留数据)
docker compose restart

# 完全重建 (删除所有数据)
docker compose down -v
docker compose up -d
```

---

**提示**: 在寻求帮助时,请提供详细的错误日志和系统信息。

