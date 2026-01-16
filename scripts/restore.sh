#!/bin/bash

# n8n 数据恢复脚本
# 用法: ./scripts/restore.sh [备份日期]
# 示例: ./scripts/restore.sh 20240115-120000

set -e

# 配置
BACKUP_DIR="./backups"
COMPOSE_FILE="docker-compose.yml"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}n8n 数据恢复工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查参数
if [ -z "$1" ]; then
    echo -e "${YELLOW}可用的备份:${NC}"
    ls -lh $BACKUP_DIR/n8n-db-*.sql.gz 2>/dev/null | awk '{print $9}' | sed 's/.*n8n-db-//' | sed 's/.sql.gz//' || echo "未找到备份文件"
    echo ""
    echo -e "${RED}用法: $0 [备份日期]${NC}"
    echo -e "${YELLOW}示例: $0 20240115-120000${NC}"
    exit 1
fi

BACKUP_DATE=$1
DB_BACKUP="$BACKUP_DIR/n8n-db-$BACKUP_DATE.sql.gz"
DATA_BACKUP="$BACKUP_DIR/n8n-data-$BACKUP_DATE.tar.gz"

# 检查备份文件是否存在
if [ ! -f "$DB_BACKUP" ]; then
    echo -e "${RED}错误: 数据库备份文件不存在: $DB_BACKUP${NC}"
    exit 1
fi

if [ ! -f "$DATA_BACKUP" ]; then
    echo -e "${YELLOW}警告: 数据卷备份文件不存在: $DATA_BACKUP${NC}"
fi

# 确认恢复操作
echo -e "${RED}警告: 此操作将覆盖当前所有数据!${NC}"
echo -e "${YELLOW}即将恢复的备份:${NC}"
echo -e "  数据库: $DB_BACKUP"
echo -e "  数据卷: $DATA_BACKUP"
echo ""
read -p "确认继续? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}操作已取消${NC}"
    exit 0
fi

# 停止 n8n 服务
echo -e "${YELLOW}正在停止 n8n 服务...${NC}"
docker compose -f $COMPOSE_FILE stop n8n
echo -e "${GREEN}✓ n8n 服务已停止${NC}"

# 恢复数据库
echo -e "${YELLOW}正在恢复数据库...${NC}"
gunzip -c $DB_BACKUP | docker compose -f $COMPOSE_FILE exec -T postgres psql -U n8n n8n
echo -e "${GREEN}✓ 数据库恢复成功${NC}"

# 恢复数据卷
if [ -f "$DATA_BACKUP" ]; then
    echo -e "${YELLOW}正在恢复数据卷...${NC}"
    docker compose -f $COMPOSE_FILE down
    docker run --rm \
        -v n8n_n8n_data:/data \
        -v $(pwd)/$BACKUP_DIR:/backup \
        alpine sh -c "rm -rf /data/* && cd /data && tar xzf /backup/n8n-data-$BACKUP_DATE.tar.gz"
    echo -e "${GREEN}✓ 数据卷恢复成功${NC}"
fi

# 重启服务
echo -e "${YELLOW}正在重启服务...${NC}"
docker compose -f $COMPOSE_FILE up -d
echo -e "${GREEN}✓ 服务已重启${NC}"

# 等待服务就绪
echo -e "${YELLOW}等待服务就绪...${NC}"
sleep 10

# 检查服务状态
if docker compose -f $COMPOSE_FILE ps | grep -q "Up"; then
    echo -e "${GREEN}✓ 服务运行正常${NC}"
else
    echo -e "${RED}✗ 服务启动异常,请检查日志${NC}"
    docker compose -f $COMPOSE_FILE logs --tail=50
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}恢复完成!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "请访问: ${YELLOW}http://localhost:5678${NC}"

