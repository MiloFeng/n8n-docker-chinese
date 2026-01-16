# 💻 Windows 用户指南

本项目完全支持 Windows 系统，本文档将帮助 Windows 用户顺利使用本项目。

## 🎯 快速开始

### 前置要求

1. **Docker Desktop for Windows**
   - 下载: https://www.docker.com/products/docker-desktop
   - 安装后重启电脑

2. **Git for Windows**（推荐）
   - 下载: https://git-scm.com/download/win
   - 安装时选择 "Git Bash Here" 选项

## 🚀 安装方式

### 方式一：使用 PowerShell 脚本（推荐）

Windows 用户可以直接使用 PowerShell 脚本：

```powershell
# 1. 克隆项目
git clone https://github.com/MiloFeng/n8n-docker-chinese.git
cd n8n-docker-chinese

# 2. 运行 PowerShell 脚本（中文版）
.\scripts\setup-chinese.ps1

# 或运行英文版
.\scripts\setup.ps1
```

### 方式二：使用 Git Bash

如果安装了 Git for Windows：

```bash
# 1. 右键点击项目文件夹
# 2. 选择 "Git Bash Here"
# 3. 运行脚本
./scripts/setup-chinese.sh
```

### 方式三：使用 WSL（Windows Subsystem for Linux）

Windows 10/11 用户推荐使用 WSL：

```bash
# 1. 启用 WSL (PowerShell 管理员模式)
wsl --install

# 2. 重启电脑

# 3. 在 WSL 中运行
cd /mnt/c/Users/YourName/n8n-docker-chinese
./scripts/setup-chinese.sh
```

### 方式四：手动安装

不想使用脚本？可以手动执行：

```powershell
# 1. 复制配置文件
copy .env.example .env

# 2. 编辑 .env 文件
notepad .env
# 修改密码和密钥

# 3. 启动服务
docker compose up -d

# 4. 访问 n8n
start http://localhost:5678
```

## 🔧 常用命令

### PowerShell 命令

```powershell
# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 查看日志
docker compose logs -f n8n

# 重启服务
docker compose restart

# 健康检查
docker compose ps

# 备份数据
.\scripts\backup.ps1

# 查看帮助
Get-Help .\scripts\setup-chinese.ps1
```

## 🐛 常见问题

### 问题 1: PowerShell 脚本无法运行

**错误信息**: "无法加载文件，因为在此系统上禁止运行脚本"

**解决方案**:
```powershell
# 以管理员身份运行 PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 然后重新运行脚本
.\scripts\setup-chinese.ps1
```

### 问题 2: Docker 命令不可用

**解决方案**:
1. 确保 Docker Desktop 已启动
2. 重启 PowerShell 或命令提示符
3. 检查 Docker 是否正常运行: `docker --version`

### 问题 3: 端口 5678 被占用

**解决方案**:
```powershell
# 查看端口占用
netstat -ano | findstr :5678

# 修改端口（编辑 .env 文件）
N8N_PORT=8080
```

### 问题 4: 路径问题

Windows 使用反斜杠 `\`，但在某些情况下需要使用正斜杠 `/`：

```powershell
# PowerShell 中使用反斜杠
.\scripts\setup-chinese.ps1

# Git Bash 中使用正斜杠
./scripts/setup-chinese.sh

# docker-compose.yml 中使用正斜杠
./n8n-local-files:/files
```

## 📝 文件路径说明

Windows 路径映射：

| Windows 路径 | WSL 路径 | Docker 路径 |
|-------------|----------|------------|
| `C:\Users\YourName\n8n` | `/mnt/c/Users/YourName/n8n` | `/files` |
| `.\backups` | `./backups` | `/backups` |

## 🎓 推荐工具

### 终端工具
- **Windows Terminal** - 微软官方终端（推荐）
- **Git Bash** - 轻量级 Bash 环境
- **WSL2** - 完整的 Linux 环境

### 编辑器
- **VS Code** - 推荐，支持 Docker 和 WSL
- **Notepad++** - 轻量级文本编辑器

### Docker 管理
- **Docker Desktop** - 官方 GUI 工具
- **Portainer** - Web 界面管理

## 🔗 相关资源

- [Docker Desktop for Windows 文档](https://docs.docker.com/desktop/windows/)
- [WSL 安装指南](https://docs.microsoft.com/zh-cn/windows/wsl/install)
- [Git for Windows](https://gitforwindows.org/)
- [Windows Terminal](https://aka.ms/terminal)

## 💡 最佳实践

1. **使用 WSL2** - 获得最佳性能和兼容性
2. **启用 Hyper-V** - Docker Desktop 需要
3. **使用 SSD** - 提升 Docker 性能
4. **定期更新** - 保持 Docker Desktop 最新版本

---

如有问题，请查看 [故障排查文档](../TROUBLESHOOTING.md) 或提交 Issue。

