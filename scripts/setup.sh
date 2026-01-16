#!/bin/bash

# n8n 快速安装脚本
# 用法: ./scripts/setup.sh

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════╗
║                                       ║
║        n8n Docker 快速安装工具        ║
║                                       ║
╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"

# 检查 Docker
echo -e "${YELLOW}检查 Docker 环境...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker 未安装${NC}"
    echo -e "${YELLOW}请先安装 Docker: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker 已安装: $(docker --version)${NC}"

# 检查 Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose 未安装${NC}"
    echo -e "${YELLOW}请先安装 Docker Compose${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose 已安装: $(docker compose version)${NC}"

echo ""
echo -e "${BLUE}请选择部署方案:${NC}"
echo -e "  ${GREEN}1${NC}) 简化版 (SQLite 数据库) - 适合快速测试"
echo -e "  ${GREEN}2${NC}) 完整版 (PostgreSQL 数据库) - 推荐生产使用"
echo -e "  ${GREEN}3${NC}) SSL 版本 (HTTPS + PostgreSQL) - 用于外网访问"
echo ""
read -p "请输入选项 (1-3): " choice

case $choice in
    1)
        COMPOSE_FILE="docker-compose.simple.yml"
        echo -e "${GREEN}已选择: 简化版${NC}"
        ;;
    2)
        COMPOSE_FILE="docker-compose.yml"
        echo -e "${GREEN}已选择: 完整版${NC}"
        ;;
    3)
        COMPOSE_FILE="docker-compose.ssl.yml"
        echo -e "${GREEN}已选择: SSL 版本${NC}"
        ;;
    *)
        echo -e "${RED}无效选项${NC}"
        exit 1
        ;;
esac

# 配置环境变量
if [ ! -f .env ]; then
    echo ""
    echo -e "${YELLOW}配置环境变量...${NC}"
    cp .env.example .env
    
    # 生成随机加密密钥
    ENCRYPTION_KEY=$(openssl rand -base64 32)
    
    # 获取用户输入
    read -p "设置管理员用户名 [admin]: " username
    username=${username:-admin}
    
    read -sp "设置管理员密码: " password
    echo ""
    
    if [ -z "$password" ]; then
        password="changeme123"
        echo -e "${YELLOW}使用默认密码: changeme123${NC}"
    fi
    
    # 更新 .env 文件
    sed -i.bak "s/N8N_BASIC_AUTH_USER=.*/N8N_BASIC_AUTH_USER=$username/" .env
    sed -i.bak "s/N8N_BASIC_AUTH_PASSWORD=.*/N8N_BASIC_AUTH_PASSWORD=$password/" .env
    sed -i.bak "s/N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$ENCRYPTION_KEY/" .env
    rm .env.bak
    
    echo -e "${GREEN}✓ 环境变量配置完成${NC}"
else
    echo -e "${YELLOW}使用现有的 .env 配置${NC}"
fi

# SSL 配置
if [ "$choice" == "3" ]; then
    echo ""
    echo -e "${YELLOW}SSL 证书配置${NC}"
    
    if [ ! -d "nginx/ssl" ]; then
        mkdir -p nginx/ssl
        
        read -p "是否生成自签名证书? (yes/no) [yes]: " gen_cert
        gen_cert=${gen_cert:-yes}
        
        if [ "$gen_cert" == "yes" ]; then
            echo -e "${YELLOW}生成自签名证书...${NC}"
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout nginx/ssl/key.pem \
                -out nginx/ssl/cert.pem \
                -subj "/C=CN/ST=Beijing/L=Beijing/O=Dev/CN=localhost"
            echo -e "${GREEN}✓ 证书生成完成${NC}"
        else
            echo -e "${YELLOW}请手动将证书文件放置到 nginx/ssl/ 目录${NC}"
            echo -e "  - nginx/ssl/cert.pem"
            echo -e "  - nginx/ssl/key.pem"
            read -p "按回车键继续..."
        fi
    fi
fi

# 创建必要的目录
mkdir -p n8n-local-files backups

# 拉取镜像
echo ""
echo -e "${YELLOW}拉取 Docker 镜像...${NC}"
docker compose -f $COMPOSE_FILE pull

# 启动服务
echo ""
echo -e "${YELLOW}启动服务...${NC}"
docker compose -f $COMPOSE_FILE up -d

# 等待服务就绪
echo -e "${YELLOW}等待服务启动...${NC}"
sleep 15

# 检查服务状态
echo ""
if docker compose -f $COMPOSE_FILE ps | grep -q "Up"; then
    echo -e "${GREEN}✓ 服务启动成功!${NC}"
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}安装完成!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    if [ "$choice" == "3" ]; then
        echo -e "访问地址: ${YELLOW}https://localhost${NC}"
    else
        echo -e "访问地址: ${YELLOW}http://localhost:5678${NC}"
    fi
    
    echo -e "用户名: ${YELLOW}$username${NC}"
    echo -e "密码: ${YELLOW}$password${NC}"
    echo ""
    echo -e "${BLUE}常用命令:${NC}"
    echo -e "  查看日志: ${YELLOW}docker compose -f $COMPOSE_FILE logs -f${NC}"
    echo -e "  停止服务: ${YELLOW}docker compose -f $COMPOSE_FILE stop${NC}"
    echo -e "  启动服务: ${YELLOW}docker compose -f $COMPOSE_FILE start${NC}"
    echo -e "  重启服务: ${YELLOW}docker compose -f $COMPOSE_FILE restart${NC}"
    echo -e "  数据备份: ${YELLOW}./scripts/backup.sh${NC}"
    echo ""
else
    echo -e "${RED}✗ 服务启动失败${NC}"
    echo -e "${YELLOW}查看日志:${NC}"
    docker compose -f $COMPOSE_FILE logs --tail=50
fi

