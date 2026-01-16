# 🚀 n8n Docker 快速部署 (中文支持)

> **一键部署 n8n 工作流自动化平台** - 完整中文界面 | 多种部署方案 | 自动化运维工具

[![Docker](https://img.shields.io/badge/docker-ready-blue)](https://www.docker.com/)
[![n8n](https://img.shields.io/badge/n8n-latest-orange)](https://n8n.io/)
[![中文](https://img.shields.io/badge/中文-支持-green)](中文配置.md)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

## 💻 平台支持

- ✅ **Linux** - 完全支持
- ✅ **macOS** - 完全支持
- ✅ **Windows** - 完全支持 ([Windows 用户指南](docs/WINDOWS.md))

## ⚡ 5 分钟快速开始

### Linux / macOS 用户

```bash
# 克隆项目
git clone https://github.com/MiloFeng/n8n-docker-chinese.git
cd n8n-docker-chinese

# 中文版 (推荐)
./scripts/setup-chinese.sh

# 英文版
./scripts/setup.sh
```

### Windows 用户

```powershell
# 克隆项目
git clone https://github.com/MiloFeng/n8n-docker-chinese.git
cd n8n-docker-chinese

# 中文版 (推荐) - 使用 PowerShell
.\scripts\setup-chinese.ps1

# 或使用 Git Bash
./scripts/setup-chinese.sh
```

> 💡 **Windows 用户**: 详细安装指南请查看 [Windows 用户指南](docs/WINDOWS.md)

### 方式二: 手动安装

```bash
# 1. 复制配置文件
cp .env.example .env

# 2. 修改密码和密钥
nano .env

# 3. 启动服务
docker compose up -d

# 4. 访问 n8n
open http://localhost:5678
```

**首次访问**: 需要创建管理员账户(邮箱、姓名、密码) ⚠️ 请使用强密码

---

## 📚 文档

### 基础文档
- 🇨🇳 [中文配置](中文配置.md) - 中文界面配置指南
- 🔧 [故障排查](TROUBLESHOOTING.md) - 常见问题解决方案
- ⚡ [性能优化](PERFORMANCE.md) - 性能调优建议
- 🤝 [贡献指南](CONTRIBUTING.md) - 如何参与项目
- 📋 [更新日志](CHANGELOG.md) - 版本历史和特性

### 高级功能
- 📊 [监控告警](monitoring/README.md) - Prometheus + Grafana 监控方案
- 💾 [备份恢复](备份恢复指南.md) - 完整备份 + 增量备份
- 🔄 [自动更新](自动更新说明.md) - Watchtower 自动更新配置

---

## 🎯 特性

### ✨ 核心功能
- ⚡ **一键部署** - 自动化安装脚本，5 分钟启动
- 🇨🇳 **中文支持** - 完整的中文界面和文档
- 🔧 **多种方案** - SQLite / PostgreSQL / MySQL / SSL
- 📦 **插件支持** - 支持社区插件 (如 MCP)

### 🛠️ 运维工具
- 💾 **自动备份** - `./scripts/backup-incremental.sh` (完整 + 增量)
- 🔄 **一键恢复** - `./scripts/restore.sh`
- 🏥 **健康检查** - `./scripts/check-health.sh`
- 🔍 **中文诊断** - `./scripts/diagnose-chinese.sh`

### 🚀 企业级功能
- 📊 **监控告警** - Prometheus + Grafana 完整监控方案
- 🔄 **自动更新** - Watchtower 自动更新容器
- 🐳 **自定义镜像** - 预装中文 UI，启动速度提升 50%
- 💾 **增量备份** - 完整备份 + 增量备份策略

---

## 📦 部署方案

### 1. 简化版 (SQLite)
适合快速测试和个人使用

```bash
docker compose -f docker-compose.simple.yml up -d
```

### 2. 完整版 (PostgreSQL) ⭐ 推荐
适合生产环境和团队使用

```bash
docker compose up -d
```

### 3. SSL 版本 (HTTPS)
适合外网访问

```bash
# 1. 配置 SSL 证书
mkdir -p nginx/ssl
# 将证书放到 nginx/ssl/ 目录

# 2. 修改域名
nano docker-compose.ssl.yml  # 修改 n8n.yourdomain.com

# 3. 启动
docker compose -f docker-compose.ssl.yml up -d
```

### 4. MySQL 版本
适合已有 MySQL 环境

```bash
docker compose -f docker-compose.mysql.yml up -d
```

### 5. 自定义镜像版 (高性能) 🚀
预装中文 UI，启动速度提升 50%

```bash
# 1. 构建自定义镜像
./scripts/build-image.sh

# 2. 使用自定义镜像
docker compose -f docker-compose.custom.yml up -d
```

### 6. 监控版 (企业级) 📊
包含 Prometheus + Grafana 监控

```bash
docker compose -f docker-compose.monitoring.yml up -d

# 访问 Grafana: http://localhost:3000 (admin/admin)
# 访问 Prometheus: http://localhost:9090
```

### 7. 自动更新版 🔄
使用 Watchtower 自动更新

```bash
docker compose -f docker-compose.watchtower.yml up -d
```

---

## 🔧 常用命令

```bash
# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 查看日志
docker compose logs -f n8n

# 重启服务
docker compose restart

# 完整备份
./scripts/backup-incremental.sh full

# 增量备份
./scripts/backup-incremental.sh inc

# 设置自动备份
./scripts/setup-auto-backup.sh

# 恢复数据
./scripts/restore.sh

# 健康检查
./scripts/check-health.sh

# 完全清理环境 (删除所有数据)
./scripts/cleanup.sh

# 清理环境但保留数据 (保留用户、工作流等)
./scripts/cleanup.sh --keep-data

# 升级 n8n
docker compose pull
docker compose down
docker compose up -d
```

---

## 🔒 安全配置

### ⚠️ 首次部署必做

1. **修改默认密码**
   ```bash
   nano .env
   # 修改 N8N_BASIC_AUTH_PASSWORD
   ```

2. **生成加密密钥**
   ```bash
   openssl rand -base64 32
   # 复制到 .env 的 N8N_ENCRYPTION_KEY
   ```

3. **重启服务**
   ```bash
   docker compose restart
   ```

### 🛡️ 生产环境建议

- ✅ 使用强密码 (至少 16 位)
- ✅ 启用 SSL/HTTPS
- ✅ 定期备份数据
- ✅ 限制网络访问
- ✅ 定期更新版本

---

## 🐛 故障排查

### 常见问题

**Q: 重启后变回英文?**  
A: 运行 `./scripts/diagnose-chinese.sh` 诊断问题

**Q: 无法访问 5678 端口?**  
A: 检查防火墙和 Docker 状态

**Q: 数据库连接失败?**  
A: 等待 PostgreSQL 启动完成 (约 10 秒)

更多问题查看 [故障排查文档](TROUBLESHOOTING.md)

---

## 📖 更多资源

- [n8n 官方文档](https://docs.n8n.io/)
- [n8n 中文汉化](https://github.com/other-blowsnow/n8n-i18n-chinese)
- [Docker 文档](https://docs.docker.com/)

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

## 📄 许可证

[MIT License](LICENSE)

---

## ⭐ Star History

如果这个项目对您有帮助，请给个 Star ⭐

---

**Made with ❤️ for n8n Chinese Community**

