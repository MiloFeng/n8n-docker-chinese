#!/bin/bash

# n8n Docker 环境清理脚本
# 用于清理 n8n 相关的 Docker 资源和临时文件
#
# 使用方法:
#   ./scripts/cleanup.sh          # 完全清理（包括数据）
#   ./scripts/cleanup.sh --keep-data  # 保留数据，只清理容器和镜像

set -e

# 默认删除数据卷
KEEP_DATA=false

# 解析命令行参数
if [ "$1" = "--keep-data" ]; then
    KEEP_DATA=true
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
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
    echo "================================"
    echo "  n8n Docker 环境清理工具"
    echo "================================"
    echo ""
}

# 确认函数
confirm_cleanup() {
    echo ""
    print_warning "此操作将删除以下内容:"
    echo "  - 所有 n8n 相关的 Docker 容器"
    echo "  - 所有 n8n 相关的 Docker 镜像"

    if [ "$KEEP_DATA" = false ]; then
        echo "  - 所有 n8n 相关的 Docker 数据卷 (包括数据库数据)"
    else
        print_info "  ✓ 数据卷将被保留 (用户、工作流等数据不会丢失)"
    fi

    echo "  - 所有 n8n 相关的 Docker 网络"
    echo "  - 项目中的临时文件 (中文 UI、备份文件等)"
    echo ""

    if [ "$KEEP_DATA" = false ]; then
        print_error "⚠️  警告: 此操作不可逆,所有数据将被永久删除!"
        echo ""
    fi

    read -p "确定要继续吗? (输入 'yes' 确认): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "已取消清理操作"
        exit 0
    fi
}

# 停止并删除容器
cleanup_containers() {
    print_info "停止并删除 Docker 容器..."

    if docker compose ps -q 2>/dev/null | grep -q .; then
        if [ "$KEEP_DATA" = true ]; then
            docker compose down
            print_success "容器已停止并删除 (数据卷已保留)"
        else
            docker compose down -v
            print_success "容器和数据卷已删除"
        fi
    else
        print_info "没有运行中的容器"
    fi
}

# 删除镜像
cleanup_images() {
    print_info "删除 n8n 相关的 Docker 镜像..."
    
    local images=$(docker images | grep n8n | awk '{print $3}' | sort -u)
    if [ -n "$images" ]; then
        echo "$images" | xargs docker rmi -f 2>/dev/null || true
        print_success "镜像已删除"
    else
        print_info "没有找到 n8n 相关镜像"
    fi
}

# 删除临时文件
cleanup_temp_files() {
    print_info "删除临时文件..."
    
    local files_to_remove=(
        "n8n-chinese-ui"
        "docker-compose.yml.backup.*"
        ".n8n-chinese-version"
        "n8n-local-files"
    )
    
    for file in "${files_to_remove[@]}"; do
        if [ -e "$file" ] || ls $file 2>/dev/null | grep -q .; then
            rm -rf $file
            print_success "已删除: $file"
        fi
    done
}

# 验证清理结果
verify_cleanup() {
    print_info "验证清理结果..."
    
    local has_resources=false
    
    # 检查容器
    if docker ps -a | grep -q n8n; then
        print_warning "仍有 n8n 容器存在"
        has_resources=true
    fi
    
    # 检查镜像
    if docker images | grep -q n8n; then
        print_warning "仍有 n8n 镜像存在"
        has_resources=true
    fi
    
    # 检查卷
    if docker volume ls | grep -q n8n; then
        print_warning "仍有 n8n 数据卷存在"
        has_resources=true
    fi
    
    # 检查网络
    if docker network ls | grep -q n8n; then
        print_warning "仍有 n8n 网络存在"
        has_resources=true
    fi
    
    if [ "$has_resources" = false ]; then
        print_success "所有 n8n 相关资源已清理完成"
    else
        print_warning "部分资源可能未完全清理,请手动检查"
    fi
}

# 主函数
main() {
    print_header
    
    # 确认清理
    confirm_cleanup
    
    echo ""
    print_info "开始清理..."
    echo ""
    
    # 执行清理
    cleanup_containers
    cleanup_images
    cleanup_temp_files
    
    echo ""
    verify_cleanup
    
    echo ""
    print_success "清理完成!"
    echo ""
}

# 运行主函数
main

