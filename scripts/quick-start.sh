#!/bin/bash

# n8n 快速启动脚本 (完全自动化)
# 用途: 无需任何交互，直接启动 n8n 中文版

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  n8n 快速启动 (中文版)${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 默认配置
DEFAULT_N8N_VERSION="1.122.5"
N8N_VERSION="${N8N_VERSION:-$DEFAULT_N8N_VERSION}"

echo -e "${GREEN}✓${NC} 使用 n8n 版本: $N8N_VERSION"
echo ""

# 1. 检查并创建 .env 文件
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠${NC} 创建 .env 配置文件..."
    cp .env.example .env
    echo -e "${GREEN}✓${NC} .env 文件已创建"
else
    echo -e "${GREEN}✓${NC} .env 文件已存在"
fi

# 2. 下载中文 UI (如果需要)
echo ""
echo -e "${BLUE}[1/3] 准备中文 UI...${NC}"

if [ -d "n8n-chinese-ui/dist" ] && [ -f "n8n-chinese-ui/.version" ]; then
    local_version=$(cat n8n-chinese-ui/.version)
    if [ "$local_version" == "$N8N_VERSION" ]; then
        echo -e "${GREEN}✓${NC} 中文 UI 已存在 (版本: $N8N_VERSION)"
    else
        echo -e "${YELLOW}⚠${NC} 版本不匹配，重新下载..."
        rm -rf n8n-chinese-ui/dist
    fi
fi

if [ ! -d "n8n-chinese-ui/dist" ]; then
    echo -e "${YELLOW}⚠${NC} 下载中文 UI (版本: $N8N_VERSION)..."
    
    download_url="https://github.com/other-blowsnow/n8n-i18n-chinese/releases/download/n8n%40${N8N_VERSION}/editor-ui.tar.gz"
    temp_dir="n8n-chinese-temp"
    
    mkdir -p "$temp_dir"
    
    if command -v wget &> /dev/null; then
        wget -q --show-progress "$download_url" -O "$temp_dir/editor-ui.tar.gz" || {
            echo -e "${YELLOW}⚠${NC} 下载失败，尝试使用最新版本..."
            N8N_VERSION="1.122.5"
            download_url="https://github.com/other-blowsnow/n8n-i18n-chinese/releases/download/n8n%40${N8N_VERSION}/editor-ui.tar.gz"
            wget -q --show-progress "$download_url" -O "$temp_dir/editor-ui.tar.gz"
        }
    else
        curl -L -# "$download_url" -o "$temp_dir/editor-ui.tar.gz" || {
            echo -e "${YELLOW}⚠${NC} 下载失败，尝试使用最新版本..."
            N8N_VERSION="1.122.5"
            download_url="https://github.com/other-blowsnow/n8n-i18n-chinese/releases/download/n8n%40${N8N_VERSION}/editor-ui.tar.gz"
            curl -L -# "$download_url" -o "$temp_dir/editor-ui.tar.gz"
        }
    fi
    
    mkdir -p n8n-chinese-ui
    tar -xzf "$temp_dir/editor-ui.tar.gz" -C n8n-chinese-ui/
    echo "$N8N_VERSION" > n8n-chinese-ui/.version
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}✓${NC} 中文 UI 下载完成"
fi

# 3. 启动 Docker Compose
echo ""
echo -e "${BLUE}[2/3] 启动 n8n 服务...${NC}"
docker compose up -d

# 4. 等待服务启动
echo ""
echo -e "${BLUE}[3/3] 等待服务启动...${NC}"
echo -e "${YELLOW}⚠${NC} 正在等待 n8n 启动 (最多等待 60 秒)..."

for i in {1..60}; do
    if docker compose ps | grep -q "Up.*healthy"; then
        echo -e "${GREEN}✓${NC} n8n 服务已启动"
        break
    fi
    
    if [ $i -eq 60 ]; then
        echo -e "${YELLOW}⚠${NC} 服务启动超时，请检查日志"
        echo ""
        echo "查看日志:"
        echo "  docker compose logs -f n8n"
        exit 1
    fi
    
    sleep 1
    echo -n "."
done

echo ""
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  🎉 n8n 启动成功！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "访问地址: ${BLUE}http://localhost:5678${NC}"
echo -e "默认账号: ${YELLOW}admin${NC}"
echo -e "默认密码: ${YELLOW}changeme123${NC}"
echo ""
echo -e "${YELLOW}⚠ 重要提示:${NC}"
echo "  1. 首次登录后请立即修改密码"
echo "  2. 修改 .env 文件中的 N8N_ENCRYPTION_KEY"
echo ""
echo "常用命令:"
echo "  查看日志: docker compose logs -f n8n"
echo "  停止服务: docker compose down"
echo "  重启服务: docker compose restart"
echo ""

