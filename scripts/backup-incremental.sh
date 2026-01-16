#!/bin/bash

# n8n 增量备份脚本
# 支持完整备份和增量备份
# 用法: 
#   ./scripts/backup-incremental.sh full    # 完整备份
#   ./scripts/backup-incremental.sh inc     # 增量备份

set -e

# 配置
BACKUP_DIR="./backups"
FULL_BACKUP_DIR="$BACKUP_DIR/full"
INC_BACKUP_DIR="$BACKUP_DIR/incremental"
SNAPSHOT_FILE="$BACKUP_DIR/.snapshot"
DATE=$(date +%Y%m%d-%H%M%S)
COMPOSE_FILE="docker-compose.yml"

# 备份保留策略
KEEP_FULL_BACKUPS=7      # 保留最近 7 个完整备份
KEEP_INC_BACKUPS=30      # 保留最近 30 个增量备份

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示帮助
show_help() {
    echo "用法: $0 [full|inc]"
    echo ""
    echo "选项:"
    echo "  full    执行完整备份"
    echo "  inc     执行增量备份 (需要先有完整备份)"
    echo ""
    echo "示例:"
    echo "  $0 full    # 每周执行一次"
    echo "  $0 inc     # 每天执行一次"
}

# 创建备份目录
mkdir -p "$FULL_BACKUP_DIR" "$INC_BACKUP_DIR"

# 清理旧备份
cleanup_old_backups() {
    echo -e "${YELLOW}清理旧备份...${NC}"
    
    # 清理旧的完整备份
    if [ -d "$FULL_BACKUP_DIR" ]; then
        cd "$FULL_BACKUP_DIR"
        ls -t | tail -n +$((KEEP_FULL_BACKUPS + 1)) | xargs -r rm -f
        cd - > /dev/null
        echo -e "${GREEN}✓ 已清理旧的完整备份 (保留最近 $KEEP_FULL_BACKUPS 个)${NC}"
    fi
    
    # 清理旧的增量备份
    if [ -d "$INC_BACKUP_DIR" ]; then
        cd "$INC_BACKUP_DIR"
        ls -t | tail -n +$((KEEP_INC_BACKUPS + 1)) | xargs -r rm -f
        cd - > /dev/null
        echo -e "${GREEN}✓ 已清理旧的增量备份 (保留最近 $KEEP_INC_BACKUPS 个)${NC}"
    fi
}

# 完整备份
full_backup() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}执行完整备份${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    BACKUP_NAME="full-$DATE"
    
    # 备份 PostgreSQL 数据库
    echo -e "${YELLOW}正在备份 PostgreSQL 数据库...${NC}"
    if docker compose -f "$COMPOSE_FILE" exec -T postgres pg_dump -U n8n n8n > "$FULL_BACKUP_DIR/$BACKUP_NAME-db.sql"; then
        gzip "$FULL_BACKUP_DIR/$BACKUP_NAME-db.sql"
        echo -e "${GREEN}✓ 数据库备份成功${NC}"
    else
        echo -e "${RED}✗ 数据库备份失败${NC}"
        return 1
    fi
    
    # 备份 n8n 数据卷
    echo -e "${YELLOW}正在备份 n8n 数据卷...${NC}"
    if docker run --rm \
        -v n8n_n8n_data:/data \
        -v "$(pwd)/$FULL_BACKUP_DIR":/backup \
        alpine tar czf "/backup/$BACKUP_NAME-data.tar.gz" -C /data . 2>/dev/null; then
        echo -e "${GREEN}✓ 数据卷备份成功${NC}"
    else
        echo -e "${RED}✗ 数据卷备份失败${NC}"
        return 1
    fi
    
    # 备份配置文件
    echo -e "${YELLOW}正在备份配置文件...${NC}"
    tar czf "$FULL_BACKUP_DIR/$BACKUP_NAME-config.tar.gz" \
        docker-compose*.yml \
        .env.example \
        scripts/ \
        2>/dev/null || true
    echo -e "${GREEN}✓ 配置文件备份成功${NC}"
    
    # 创建快照文件 (记录完整备份时间)
    echo "$DATE" > "$SNAPSHOT_FILE"
    echo -e "${GREEN}✓ 快照文件已创建${NC}"
    
    # 创建备份清单
    cat > "$FULL_BACKUP_DIR/$BACKUP_NAME-manifest.txt" << EOF
备份类型: 完整备份
备份时间: $DATE
备份文件:
  - $BACKUP_NAME-db.sql.gz
  - $BACKUP_NAME-data.tar.gz
  - $BACKUP_NAME-config.tar.gz
EOF
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}完整备份完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "备份位置: $FULL_BACKUP_DIR"
    echo -e "备份名称: $BACKUP_NAME"
    
    # 显示备份大小
    du -sh "$FULL_BACKUP_DIR/$BACKUP_NAME"* | sed 's/^/  /'
}

# 增量备份
incremental_backup() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}执行增量备份${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # 检查是否存在完整备份
    if [ ! -f "$SNAPSHOT_FILE" ]; then
        echo -e "${RED}✗ 未找到完整备份，请先执行完整备份${NC}"
        echo -e "${YELLOW}运行: $0 full${NC}"
        return 1
    fi
    
    LAST_FULL_BACKUP=$(cat "$SNAPSHOT_FILE")
    BACKUP_NAME="inc-$DATE"
    
    echo -e "${BLUE}基于完整备份: $LAST_FULL_BACKUP${NC}"
    echo ""
    
    # 增量备份数据库 (仅备份变更)
    echo -e "${YELLOW}正在备份数据库变更...${NC}"
    if docker compose -f "$COMPOSE_FILE" exec -T postgres pg_dump -U n8n n8n > "$INC_BACKUP_DIR/$BACKUP_NAME-db.sql"; then
        gzip "$INC_BACKUP_DIR/$BACKUP_NAME-db.sql"
        echo -e "${GREEN}✓ 数据库增量备份成功${NC}"
    else
        echo -e "${RED}✗ 数据库增量备份失败${NC}"
        return 1
    fi
    
    # 增量备份数据卷 (仅备份修改的文件)
    echo -e "${YELLOW}正在备份数据卷变更...${NC}"
    if docker run --rm \
        -v n8n_n8n_data:/data \
        -v "$(pwd)/$INC_BACKUP_DIR":/backup \
        alpine sh -c "find /data -type f -newer /data/.backup_marker 2>/dev/null | tar czf /backup/$BACKUP_NAME-data.tar.gz -T - 2>/dev/null || tar czf /backup/$BACKUP_NAME-data.tar.gz -C /data ." 2>/dev/null; then
        echo -e "${GREEN}✓ 数据卷增量备份成功${NC}"
    else
        echo -e "${RED}✗ 数据卷增量备份失败${NC}"
        return 1
    fi
    
    # 创建备份清单
    cat > "$INC_BACKUP_DIR/$BACKUP_NAME-manifest.txt" << EOF
备份类型: 增量备份
备份时间: $DATE
基于完整备份: $LAST_FULL_BACKUP
备份文件:
  - $BACKUP_NAME-db.sql.gz
  - $BACKUP_NAME-data.tar.gz
EOF
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}增量备份完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "备份位置: $INC_BACKUP_DIR"
    echo -e "备份名称: $BACKUP_NAME"
    
    # 显示备份大小
    du -sh "$INC_BACKUP_DIR/$BACKUP_NAME"* | sed 's/^/  /'
}

# 主程序
main() {
    case "${1:-}" in
        full)
            full_backup
            cleanup_old_backups
            ;;
        inc)
            incremental_backup
            cleanup_old_backups
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

main "$@"

