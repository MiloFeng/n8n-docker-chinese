#!/bin/bash

# n8n 中文界面一键配置脚本
# 作者: n8n Docker 部署项目
# 用途: 自动下载并配置 n8n 中文界面
#
# 使用方法:
#   1. 自动检测版本: ./scripts/setup-chinese.sh
#   2. 指定版本: N8N_VERSION=1.122.5 ./scripts/setup-chinese.sh
#   3. 使用最新版本: N8N_VERSION=latest ./scripts/setup-chinese.sh
#   4. 完全自动化: N8N_VERSION=1.122.5 AUTO_CONFIRM=yes ./scripts/setup-chinese.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}  n8n 中文界面配置工具${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
}

# 检查依赖
check_dependencies() {
    print_info "检查依赖..."
    
    local missing_deps=()
    
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        missing_deps+=("wget 或 curl")
    fi
    
    if ! command -v tar &> /dev/null; then
        missing_deps+=("tar")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "缺少以下依赖: ${missing_deps[*]}"
        exit 1
    fi
    
    print_success "依赖检查通过"
}

# 获取 n8n 版本
get_n8n_version() {
    # 如果环境变量已设置,直接使用
    if [ -n "$N8N_VERSION" ]; then
        print_success "使用环境变量指定的版本: $N8N_VERSION"
        return 0
    fi

    print_info "检测 n8n 版本..."

    # 尝试从运行中的容器获取版本
    if docker ps --format '{{.Names}}' | grep -q "n8n"; then
        local container_name=$(docker ps --format '{{.Names}}' | grep "n8n" | head -n 1)
        N8N_VERSION=$(docker exec "$container_name" n8n --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "")

        if [ -n "$N8N_VERSION" ]; then
            print_success "检测到 n8n 版本: $N8N_VERSION"
            return 0
        fi
    fi
    
    # 如果无法自动检测,尝试获取最新版本或使用默认值
    print_warning "无法自动检测 n8n 版本"
    echo ""

    # 尝试从 GitHub API 获取最新版本
    print_info "尝试获取最新的 n8n 中文版本..."
    local latest_version=""

    if command -v curl &> /dev/null; then
        latest_version=$(curl -s "https://api.github.com/repos/other-blowsnow/n8n-i18n-chinese/releases/latest" | grep -oP '"tag_name": "n8n@\K[^"]+' 2>/dev/null || echo "")
    fi

    if [ -n "$latest_version" ]; then
        print_success "检测到最新中文版本: $latest_version"
        read -p "是否使用此版本? [Y/n]: " use_latest
        if [[ ! $use_latest =~ ^[Nn]$ ]]; then
            N8N_VERSION="$latest_version"
            return 0
        fi
    fi

    # 提供默认版本选项
    local default_version="2.3.5"
    echo ""
    echo "请访问以下链接查看可用的中文版本:"
    echo "https://github.com/other-blowsnow/n8n-i18n-chinese/releases"
    echo ""
    read -p "请输入 n8n 版本号 (直接回车使用默认版本 $default_version): " N8N_VERSION

    # 如果用户直接回车,使用默认版本
    if [ -z "$N8N_VERSION" ]; then
        N8N_VERSION="$default_version"
        print_info "使用默认版本: $N8N_VERSION"
    fi
}

# 检查本地是否已有中文 UI
check_local_ui() {
    local target_dir="n8n-chinese-ui"
    local version_file="$target_dir/.version"

    if [ -d "$target_dir/dist" ] && [ -f "$version_file" ]; then
        local local_version=$(cat "$version_file")
        if [ "$local_version" == "$N8N_VERSION" ]; then
            print_success "检测到本地已有 v$N8N_VERSION 中文 UI"
            read -p "是否跳过下载? [Y/n]: " skip_download
            if [[ ! $skip_download =~ ^[Nn]$ ]]; then
                return 0
            fi
        else
            print_info "本地版本 ($local_version) 与目标版本 ($N8N_VERSION) 不匹配"
        fi
    fi
    return 1
}

# 下载中文 UI
download_chinese_ui() {
    # 检查本地缓存
    if check_local_ui; then
        print_success "使用本地缓存的中文 UI"
        return 0
    fi

    print_info "下载中文 UI 文件..."

    local download_url="https://github.com/other-blowsnow/n8n-i18n-chinese/releases/download/n8n%40${N8N_VERSION}/editor-ui.tar.gz"
    local temp_dir="n8n-chinese-temp"
    local target_dir="n8n-chinese-ui"
    local version_file="$target_dir/.version"

    # 创建临时目录
    mkdir -p "$temp_dir"
    cd "$temp_dir"

    # 下载文件
    print_info "从 GitHub 下载中文 UI (版本: $N8N_VERSION)..."
    if command -v wget &> /dev/null; then
        if wget -q --show-progress "$download_url" -O editor-ui.tar.gz; then
            print_success "下载成功"
        else
            print_error "下载失败,请检查版本号是否正确"
            print_info "可用版本列表: https://github.com/other-blowsnow/n8n-i18n-chinese/releases"
            cd ..
            rm -rf "$temp_dir"
            exit 1
        fi
    else
        if curl -L -# "$download_url" -o editor-ui.tar.gz; then
            print_success "下载成功"
        else
            print_error "下载失败,请检查版本号是否正确"
            print_info "可用版本列表: https://github.com/other-blowsnow/n8n-i18n-chinese/releases"
            cd ..
            rm -rf "$temp_dir"
            exit 1
        fi
    fi

    # 验证下载的文件
    print_info "验证下载的文件..."
    if ! tar -tzf editor-ui.tar.gz > /dev/null 2>&1; then
        print_error "下载的文件损坏,请重试"
        cd ..
        rm -rf "$temp_dir"
        exit 1
    fi
    print_success "文件验证通过"

    # 备份旧版本
    cd ..
    if [ -d "$target_dir/dist" ]; then
        print_info "备份旧版本..."
        mv "$target_dir/dist" "$target_dir/dist.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "备份完成"
    fi

    # 解压新版本
    print_info "解压中文 UI 文件..."
    mkdir -p "$target_dir"
    tar -xzf "$temp_dir/editor-ui.tar.gz" -C "$target_dir/"
    print_success "解压完成"

    # 保存版本信息
    echo "$N8N_VERSION" > "$version_file"
    print_success "版本信息已保存"

    # 清理临时文件
    rm -rf "$temp_dir"
    print_success "中文 UI 文件准备完成 (版本: $N8N_VERSION)"
}

# 选择部署方式
choose_deployment_method() {
    echo ""
    print_info "请选择部署方式:"
    echo ""
    echo "  1) 修改现有的 docker-compose.yml (推荐)"
    echo "  2) 创建新的 docker-compose.chinese.yml"
    echo "  3) 使用中文版 Docker 镜像 (最简单)"
    echo "  4) 仅下载中文 UI,手动配置"
    echo ""
    read -p "请选择 [1-4]: " choice
    
    case $choice in
        1)
            update_existing_compose
            ;;
        2)
            create_new_compose
            ;;
        3)
            use_chinese_image
            ;;
        4)
            print_success "中文 UI 文件已下载到: $(pwd)/n8n-chinese-ui/dist"
            print_info "请参考文档手动配置: docs/CHINESE_LOCALIZATION.md"
            ;;
        *)
            print_error "无效的选择"
            exit 1
            ;;
    esac
}

# 更新现有的 docker-compose.yml
update_existing_compose() {
    print_info "更新现有的 docker-compose.yml..."

    if [ ! -f "docker-compose.yml" ]; then
        print_error "未找到 docker-compose.yml 文件"
        exit 1
    fi

    # 备份原文件
    cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
    print_success "已备份原配置文件"

    # 检查是否已经配置了中文 (支持多种格式)
    if grep -q "N8N_DEFAULT_LOCALE.*zh-CN" docker-compose.yml; then
        print_success "检测到已配置中文语言环境变量"
    else
        print_info "添加中文语言环境变量..."
        # 这里需要手动添加,因为 YAML 格式复杂
        print_warning "请手动在 docker-compose.yml 的 environment 部分添加:"
        echo ""
        echo "      - N8N_DEFAULT_LOCALE=zh-CN"
        echo "      - GENERIC_TIMEZONE=Asia/Shanghai"
        echo "      - TZ=Asia/Shanghai"
        echo ""
    fi

    # 检查是否已经挂载了中文 UI
    if grep -q "n8n-editor-ui/dist" docker-compose.yml; then
        print_warning "检测到已配置 UI 文件挂载"
    else
        print_warning "请手动在 docker-compose.yml 的 volumes 部分添加:"
        echo ""
        echo "      - ./n8n-chinese-ui/dist:/usr/local/lib/node_modules/n8n/node_modules/n8n-editor-ui/dist"
        echo ""
    fi

    print_info "配置完成后,请运行以下命令重启服务:"
    echo ""
    echo "  docker compose down"
    echo "  docker compose up -d"
    echo ""
}

# 创建新的 docker-compose 文件
create_new_compose() {
    print_info "创建 docker-compose.chinese.yml..."

    cat > docker-compose.chinese.yml << 'EOF'
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n-chinese
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      # 认证配置
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=changeme123

      # 中文语言配置 ⭐
      - N8N_DEFAULT_LOCALE=zh-CN

      # 数据库配置
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=n8n_password

      # 时区配置
      - GENERIC_TIMEZONE=Asia/Shanghai
      - TZ=Asia/Shanghai

      # 其他配置
      - WEBHOOK_URL=http://localhost:5678/
      - N8N_ENCRYPTION_KEY=change-this-to-random-string
    volumes:
      - n8n_data:/home/node/.n8n
      # 中文 UI 文件挂载 ⭐
      - ./n8n-chinese-ui/dist:/usr/local/lib/node_modules/n8n/node_modules/n8n-editor-ui/dist
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - n8n-network

  postgres:
    image: postgres:15-alpine
    container_name: n8n-postgres-chinese
    restart: unless-stopped
    environment:
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=n8n_password
      - POSTGRES_DB=n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -h localhost -U n8n -d n8n']
      interval: 5s
      timeout: 5s
      retries: 10
    networks:
      - n8n-network

volumes:
  n8n_data:
    driver: local
  postgres_data:
    driver: local

networks:
  n8n-network:
    driver: bridge
EOF

    print_success "已创建 docker-compose.chinese.yml"

    print_warning "⚠️  重要提示:"
    echo ""
    echo "1. 请修改默认密码 (N8N_BASIC_AUTH_PASSWORD)"
    echo "2. 请生成随机加密密钥 (N8N_ENCRYPTION_KEY)"
    echo "   运行: openssl rand -base64 32"
    echo ""

    read -p "是否现在启动中文版 n8n? [y/N]: " start_now
    if [[ $start_now =~ ^[Yy]$ ]]; then
        print_info "启动服务..."
        docker compose -f docker-compose.chinese.yml up -d
        print_success "服务已启动!"
        print_info "访问地址: http://localhost:5678"
    else
        print_info "稍后可以运行以下命令启动:"
        echo ""
        echo "  docker compose -f docker-compose.chinese.yml up -d"
        echo ""
    fi
}

# 使用中文版 Docker 镜像
use_chinese_image() {
    print_info "使用中文版 Docker 镜像..."

    echo ""
    print_info "停止现有服务..."
    docker compose down 2>/dev/null || true

    print_info "拉取中文版镜像..."
    docker pull hotwa/n8n-chinese:latest

    print_info "启动中文版 n8n..."
    docker run -d \
        --name n8n-chinese \
        -p 5678:5678 \
        -v n8n_data:/home/node/.n8n \
        -e N8N_DEFAULT_LOCALE=zh-CN \
        -e GENERIC_TIMEZONE=Asia/Shanghai \
        -e TZ=Asia/Shanghai \
        -e N8N_BASIC_AUTH_ACTIVE=true \
        -e N8N_BASIC_AUTH_USER=admin \
        -e N8N_BASIC_AUTH_PASSWORD=changeme123 \
        hotwa/n8n-chinese:latest

    print_success "中文版 n8n 已启动!"
    print_info "访问地址: http://localhost:5678"
    print_warning "默认用户名: admin"
    print_warning "默认密码: changeme123 (请立即修改!)"
}

# 主函数
main() {
    print_header

    # 检查依赖
    check_dependencies

    # 获取 n8n 版本
    get_n8n_version

    # 下载中文 UI
    download_chinese_ui

    # 选择部署方式
    choose_deployment_method

    echo ""
    print_success "配置完成!"
    echo ""
    print_info "相关文档:"
    echo "  - 中文配置指南: docs/CHINESE_LOCALIZATION.md"
    echo "  - 项目主页: https://github.com/other-blowsnow/n8n-i18n-chinese"
    echo ""
}

# 运行主函数
main

