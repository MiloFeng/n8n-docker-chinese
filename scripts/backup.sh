#!/bin/bash

# n8n 数据备份脚本
# 用法: ./scripts/backup.sh

set -e

# 配置
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d-%H%M%S)
COMPOSE_FILE="docker-compose.yml"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}n8n 数据备份工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 创建备份目录
mkdir -p $BACKUP_DIR

# 检查 Docker Compose 是否运行
if ! docker compose -f $COMPOSE_FILE ps | grep -q "Up"; then
    echo -e "${YELLOW}警告: 某些服务未运行,备份可能不完整${NC}"
fi

# 备份 PostgreSQL 数据库
echo -e "${YELLOW}正在备份 PostgreSQL 数据库...${NC}"
if docker compose -f $COMPOSE_FILE exec -T postgres pg_dump -U n8n n8n > $BACKUP_DIR/n8n-db-$DATE.sql; then
    echo -e "${GREEN}✓ 数据库备份成功: $BACKUP_DIR/n8n-db-$DATE.sql${NC}"
    
    # 压缩数据库备份
    gzip $BACKUP_DIR/n8n-db-$DATE.sql
    echo -e "${GREEN}✓ 数据库备份已压缩: $BACKUP_DIR/n8n-db-$DATE.sql.gz${NC}"
else
    echo -e "${RED}✗ 数据库备份失败${NC}"
fi

# 备份 n8n 数据卷
echo -e "${YELLOW}正在备份 n8n 数据卷...${NC}"
if docker run --rm \
    -v n8n_n8n_data:/data \
    -v $(pwd)/$BACKUP_DIR:/backup \
    alpine tar czf /backup/n8n-data-$DATE.tar.gz -C /data . 2>/dev/null; then
    echo -e "${GREEN}✓ 数据卷备份成功: $BACKUP_DIR/n8n-data-$DATE.tar.gz${NC}"
else
    echo -e "${RED}✗ 数据卷备份失败${NC}"
fi

# 备份配置文件
echo -e "${YELLOW}正在备份配置文件...${NC}"
tar czf $BACKUP_DIR/n8n-config-$DATE.tar.gz \
    docker-compose.yml \
    .env \
    nginx/ 2>/dev/null || true
echo -e "${GREEN}✓ 配置文件备份成功: $BACKUP_DIR/n8n-config-$DATE.tar.gz${NC}"

# 显示备份信息
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}备份完成!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "备份位置: ${YELLOW}$BACKUP_DIR${NC}"
echo -e "备份时间: ${YELLOW}$(date)${NC}"
echo ""
ls -lh $BACKUP_DIR/*$DATE* 2>/dev/null || true

# 清理旧备份 (保留最近 7 天)
echo ""
echo -e "${YELLOW}清理 7 天前的旧备份...${NC}"
find $BACKUP_DIR -name "n8n-*" -type f -mtime +7 -delete 2>/dev/null || true
echo -e "${GREEN}✓ 清理完成${NC}"

echo ""
echo -e "${GREEN}提示: 请定期将备份文件复制到安全的位置${NC}"

