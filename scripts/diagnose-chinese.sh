#!/bin/bash

# n8n 中文界面诊断脚本
# 用于诊断中文界面配置问题

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  n8n 中文界面诊断工具${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 1. 检查容器是否运行
echo -e "${YELLOW}[1/6] 检查 n8n 容器状态...${NC}"
if docker ps --format '{{.Names}}' | grep -q "n8n"; then
    CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep "n8n" | head -n 1)
    echo -e "${GREEN}✓${NC} 容器运行中: $CONTAINER_NAME"
else
    echo -e "${RED}✗${NC} n8n 容器未运行"
    echo "请先启动 n8n: docker compose up -d"
    exit 1
fi

# 2. 检查环境变量
echo ""
echo -e "${YELLOW}[2/6] 检查语言环境变量...${NC}"
LOCALE=$(docker exec "$CONTAINER_NAME" env | grep "N8N_DEFAULT_LOCALE" || echo "")
if [ -n "$LOCALE" ]; then
    echo -e "${GREEN}✓${NC} $LOCALE"
else
    echo -e "${RED}✗${NC} 未设置 N8N_DEFAULT_LOCALE"
    echo "需要在 docker-compose.yml 中添加: N8N_DEFAULT_LOCALE=zh-CN"
fi

# 3. 检查时区配置
echo ""
echo -e "${YELLOW}[3/6] 检查时区配置...${NC}"
TIMEZONE=$(docker exec "$CONTAINER_NAME" env | grep "GENERIC_TIMEZONE" || echo "")
TZ=$(docker exec "$CONTAINER_NAME" env | grep "^TZ=" || echo "")
if [ -n "$TIMEZONE" ]; then
    echo -e "${GREEN}✓${NC} $TIMEZONE"
else
    echo -e "${YELLOW}⚠${NC} 未设置 GENERIC_TIMEZONE (建议设置为 Asia/Shanghai)"
fi
if [ -n "$TZ" ]; then
    echo -e "${GREEN}✓${NC} $TZ"
else
    echo -e "${YELLOW}⚠${NC} 未设置 TZ (建议设置为 Asia/Shanghai)"
fi

# 4. 检查中文 UI 文件挂载
echo ""
echo -e "${YELLOW}[4/6] 检查中文 UI 文件...${NC}"
if docker exec "$CONTAINER_NAME" test -f /usr/local/lib/node_modules/n8n/node_modules/n8n-editor-ui/dist/index.html; then
    echo -e "${GREEN}✓${NC} UI 文件存在"
    
    # 检查文件大小
    SIZE=$(docker exec "$CONTAINER_NAME" stat -f%z /usr/local/lib/node_modules/n8n/node_modules/n8n-editor-ui/dist/index.html 2>/dev/null || docker exec "$CONTAINER_NAME" stat -c%s /usr/local/lib/node_modules/n8n/node_modules/n8n-editor-ui/dist/index.html 2>/dev/null || echo "0")
    if [ "$SIZE" -gt 1000 ]; then
        echo -e "${GREEN}✓${NC} UI 文件大小正常: $SIZE bytes"
    else
        echo -e "${RED}✗${NC} UI 文件可能损坏"
    fi
else
    echo -e "${RED}✗${NC} UI 文件不存在"
    echo "请检查 volumes 挂载配置"
fi

# 5. 检查 docker-compose.yml 配置
echo ""
echo -e "${YELLOW}[5/6] 检查 docker-compose.yml 配置...${NC}"
if [ -f "docker-compose.yml" ]; then
    if grep -q "N8N_DEFAULT_LOCALE" docker-compose.yml; then
        echo -e "${GREEN}✓${NC} docker-compose.yml 包含语言配置"
    else
        echo -e "${RED}✗${NC} docker-compose.yml 缺少 N8N_DEFAULT_LOCALE"
    fi
    
    if grep -q "n8n-editor-ui/dist" docker-compose.yml; then
        echo -e "${GREEN}✓${NC} docker-compose.yml 包含 UI 挂载配置"
    else
        echo -e "${RED}✗${NC} docker-compose.yml 缺少 UI 文件挂载"
    fi
else
    echo -e "${YELLOW}⚠${NC} 未找到 docker-compose.yml"
fi

# 6. 检查本地中文 UI 文件
echo ""
echo -e "${YELLOW}[6/6] 检查本地中文 UI 文件...${NC}"
if [ -d "n8n-chinese-ui/dist" ]; then
    FILE_COUNT=$(find n8n-chinese-ui/dist -type f | wc -l)
    echo -e "${GREEN}✓${NC} 本地中文 UI 文件存在 ($FILE_COUNT 个文件)"
else
    echo -e "${RED}✗${NC} 本地中文 UI 文件不存在"
    echo "请运行: ./scripts/setup-chinese.sh"
fi

# 总结
echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  诊断总结${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 提供修复建议
if [ -z "$LOCALE" ]; then
    echo -e "${YELLOW}修复建议:${NC}"
    echo "1. 编辑 docker-compose.yml"
    echo "2. 在 environment 部分添加:"
    echo "   - N8N_DEFAULT_LOCALE=zh-CN"
    echo "   - GENERIC_TIMEZONE=Asia/Shanghai"
    echo "   - TZ=Asia/Shanghai"
    echo "3. 重启服务: docker compose restart"
    echo ""
fi

if ! grep -q "n8n-editor-ui/dist" docker-compose.yml 2>/dev/null; then
    echo -e "${YELLOW}修复建议:${NC}"
    echo "1. 确保已下载中文 UI 文件"
    echo "2. 在 docker-compose.yml 的 volumes 部分添加:"
    echo "   - ./n8n-chinese-ui/dist:/usr/local/lib/node_modules/n8n/node_modules/n8n-editor-ui/dist"
    echo "3. 重启服务: docker compose down && docker compose up -d"
    echo ""
fi

echo -e "${GREEN}提示:${NC} 如果问题仍然存在,请运行:"
echo "  ./scripts/setup-chinese.sh"
echo ""

