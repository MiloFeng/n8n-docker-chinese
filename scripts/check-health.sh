#!/bin/bash

# n8n 健康检查脚本
# 用法: ./scripts/check-health.sh

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}n8n 健康检查工具${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查 Docker
echo -e "${YELLOW}[1/6] 检查 Docker...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker 已安装: $(docker --version)${NC}"
else
    echo -e "${RED}✗ Docker 未安装${NC}"
    exit 1
fi

# 检查 Docker Compose
echo -e "${YELLOW}[2/6] 检查 Docker Compose...${NC}"
if docker compose version &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose 已安装: $(docker compose version --short)${NC}"
else
    echo -e "${RED}✗ Docker Compose 未安装${NC}"
    exit 1
fi

# 检查容器状态
echo -e "${YELLOW}[3/6] 检查容器状态...${NC}"
if docker compose ps | grep -q "Up"; then
    echo -e "${GREEN}✓ 容器正在运行${NC}"
    docker compose ps
else
    echo -e "${RED}✗ 容器未运行${NC}"
    echo -e "${YELLOW}提示: 运行 'docker compose up -d' 启动服务${NC}"
fi

# 检查端口
echo ""
echo -e "${YELLOW}[4/6] 检查端口...${NC}"
if lsof -i :5678 &> /dev/null || netstat -an 2>/dev/null | grep -q ":5678"; then
    echo -e "${GREEN}✓ 端口 5678 已开放${NC}"
else
    echo -e "${YELLOW}⚠ 端口 5678 未监听${NC}"
fi

# 检查服务响应
echo ""
echo -e "${YELLOW}[5/6] 检查服务响应...${NC}"
if curl -f -s http://localhost:5678 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ n8n 服务响应正常${NC}"
    echo -e "${GREEN}  访问地址: http://localhost:5678${NC}"
else
    echo -e "${YELLOW}⚠ n8n 服务未响应${NC}"
    echo -e "${YELLOW}  请检查日志: docker compose logs -f${NC}"
fi

# 检查数据库
echo ""
echo -e "${YELLOW}[6/6] 检查数据库...${NC}"
if docker compose ps postgres &> /dev/null; then
    if docker compose exec -T postgres pg_isready -U n8n &> /dev/null; then
        echo -e "${GREEN}✓ PostgreSQL 数据库正常${NC}"
    else
        echo -e "${YELLOW}⚠ PostgreSQL 数据库未就绪${NC}"
    fi
elif docker compose ps mysql &> /dev/null; then
    if docker compose exec -T mysql mysqladmin ping -h localhost -u n8n -pn8n_password &> /dev/null; then
        echo -e "${GREEN}✓ MySQL 数据库正常${NC}"
    else
        echo -e "${YELLOW}⚠ MySQL 数据库未就绪${NC}"
    fi
else
    echo -e "${BLUE}ℹ 使用 SQLite 数据库${NC}"
fi

# 资源使用情况
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}资源使用情况${NC}"
echo -e "${BLUE}========================================${NC}"
docker stats --no-stream 2>/dev/null || echo -e "${YELLOW}无法获取资源信息${NC}"

# 磁盘空间
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}磁盘空间${NC}"
echo -e "${BLUE}========================================${NC}"
df -h | grep -E "Filesystem|/$" || df -h

# 数据卷信息
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}数据卷信息${NC}"
echo -e "${BLUE}========================================${NC}"
docker volume ls | grep n8n || echo -e "${YELLOW}未找到 n8n 数据卷${NC}"

# 备份信息
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}备份信息${NC}"
echo -e "${BLUE}========================================${NC}"
if [ -d "backups" ] && [ "$(ls -A backups 2>/dev/null)" ]; then
    echo -e "${GREEN}最近的备份:${NC}"
    ls -lht backups/ | head -5
else
    echo -e "${YELLOW}⚠ 未找到备份文件${NC}"
    echo -e "${YELLOW}  建议运行: ./scripts/backup.sh${NC}"
fi

# 总结
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}检查完成${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 提供建议
if docker compose ps | grep -q "Up" && curl -f -s http://localhost:5678 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 系统运行正常!${NC}"
    echo ""
    echo -e "${GREEN}访问地址: http://localhost:5678${NC}"
    echo -e "${GREEN}默认用户名: admin${NC}"
    echo -e "${GREEN}默认密码: changeme123${NC}"
else
    echo -e "${YELLOW}⚠ 系统可能存在问题${NC}"
    echo ""
    echo -e "${YELLOW}建议操作:${NC}"
    echo -e "  1. 查看日志: ${BLUE}docker compose logs -f${NC}"
    echo -e "  2. 重启服务: ${BLUE}docker compose restart${NC}"
    echo -e "  3. 查看文档: ${BLUE}cat TROUBLESHOOTING.md${NC}"
fi

echo ""
echo -e "${BLUE}常用命令:${NC}"
echo -e "  查看日志: ${YELLOW}make logs${NC} 或 ${YELLOW}docker compose logs -f${NC}"
echo -e "  重启服务: ${YELLOW}make restart${NC} 或 ${YELLOW}docker compose restart${NC}"
echo -e "  备份数据: ${YELLOW}make backup${NC} 或 ${YELLOW}./scripts/backup.sh${NC}"
echo -e "  查看帮助: ${YELLOW}make help${NC}"
echo ""

