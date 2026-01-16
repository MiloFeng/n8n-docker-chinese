#!/bin/bash

# MCP 插件安装检查脚本

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  MCP 插件安装检查${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 检查容器是否运行
echo -e "${YELLOW}[1/3] 检查 n8n 容器状态...${NC}"
if docker ps --format '{{.Names}}' | grep -q "n8n"; then
    echo -e "${GREEN}✓${NC} n8n 容器运行中"
else
    echo -e "${RED}✗${NC} n8n 容器未运行"
    exit 1
fi

# 检查环境变量
echo ""
echo -e "${YELLOW}[2/3] 检查社区节点配置...${NC}"
COMMUNITY_ENABLED=$(docker exec n8n env | grep "N8N_COMMUNITY_PACKAGES_ENABLED" || echo "")
COMMUNITY_PACKAGES=$(docker exec n8n env | grep "N8N_COMMUNITY_PACKAGES" || echo "")

if [ -n "$COMMUNITY_ENABLED" ]; then
    echo -e "${GREEN}✓${NC} $COMMUNITY_ENABLED"
else
    echo -e "${RED}✗${NC} 未启用社区节点"
fi

if [ -n "$COMMUNITY_PACKAGES" ]; then
    echo -e "${GREEN}✓${NC} $COMMUNITY_PACKAGES"
else
    echo -e "${YELLOW}⚠${NC} 未配置社区节点包"
fi

# 检查插件是否已安装
echo ""
echo -e "${YELLOW}[3/3] 检查 MCP 插件安装状态...${NC}"
if docker exec n8n ls /home/node/.n8n/nodes 2>/dev/null | grep -q "n8n-nodes-mcp"; then
    echo -e "${GREEN}✓${NC} MCP 插件已安装"
    echo ""
    echo -e "${GREEN}安装成功!${NC}"
    echo ""
    echo "下一步:"
    echo "1. 访问 n8n: http://localhost:5678"
    echo "2. 创建新工作流"
    echo "3. 搜索 'MCP' 节点"
    echo "4. 开始使用 MCP 功能"
else
    echo -e "${YELLOW}⚠${NC} MCP 插件正在安装中..."
    echo ""
    echo "插件安装需要几分钟时间，请稍候。"
    echo ""
    echo "查看安装进度:"
    echo "  docker compose logs -f n8n"
    echo ""
    echo "安装完成后，刷新 n8n 页面即可使用。"
fi

echo ""
echo -e "${BLUE}================================${NC}"
echo ""

