#!/bin/bash

# n8n 自定义镜像构建脚本
# 用于构建预装中文 UI 的 n8n Docker 镜像

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认配置
IMAGE_NAME="${IMAGE_NAME:-n8n-chinese}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
N8N_VERSION="${N8N_VERSION:-latest}"
CHINESE_UI_VERSION="${CHINESE_UI_VERSION:-latest}"
REGISTRY="${REGISTRY:-}"  # 留空表示本地构建

echo -e "${GREEN}=== n8n 自定义镜像构建 ===${NC}"
echo ""
echo "配置信息:"
echo "  镜像名称: ${IMAGE_NAME}"
echo "  镜像标签: ${IMAGE_TAG}"
echo "  n8n 版本: ${N8N_VERSION}"
echo "  中文 UI 版本: ${CHINESE_UI_VERSION}"
if [ -n "$REGISTRY" ]; then
    echo "  镜像仓库: ${REGISTRY}"
fi
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装${NC}"
    exit 1
fi

# 检查 Dockerfile 是否存在
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}❌ Dockerfile 不存在${NC}"
    exit 1
fi

# 构建镜像
echo -e "${YELLOW}📦 开始构建镜像...${NC}"
echo ""

FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
if [ -n "$REGISTRY" ]; then
    FULL_IMAGE_NAME="${REGISTRY}/${FULL_IMAGE_NAME}"
fi

docker build \
    --build-arg N8N_VERSION="${N8N_VERSION}" \
    --build-arg CHINESE_UI_VERSION="${CHINESE_UI_VERSION}" \
    -t "${FULL_IMAGE_NAME}" \
    -f Dockerfile \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ 镜像构建成功！${NC}"
    echo ""
    echo "镜像信息:"
    docker images "${FULL_IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    echo ""
    
    # 显示使用说明
    echo -e "${GREEN}📝 使用方法:${NC}"
    echo ""
    echo "1. 本地运行:"
    echo "   docker run -d -p 5678:5678 ${FULL_IMAGE_NAME}"
    echo ""
    echo "2. 使用 docker-compose:"
    echo "   修改 docker-compose.yml 中的 image 为: ${FULL_IMAGE_NAME}"
    echo ""
    
    if [ -n "$REGISTRY" ]; then
        echo "3. 推送到镜像仓库:"
        echo "   docker push ${FULL_IMAGE_NAME}"
        echo ""
    fi
    
    echo -e "${YELLOW}💡 提示:${NC}"
    echo "  - 镜像已预装中文 UI，无需额外下载"
    echo "  - 启动速度更快"
    echo "  - 可以离线使用"
    echo ""
else
    echo ""
    echo -e "${RED}❌ 镜像构建失败${NC}"
    exit 1
fi

# 询问是否推送
if [ -n "$REGISTRY" ]; then
    echo ""
    read -p "是否推送镜像到仓库? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}📤 推送镜像...${NC}"
        docker push "${FULL_IMAGE_NAME}"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ 镜像推送成功！${NC}"
        else
            echo -e "${RED}❌ 镜像推送失败${NC}"
            exit 1
        fi
    fi
fi

echo ""
echo -e "${GREEN}🎉 完成！${NC}"

