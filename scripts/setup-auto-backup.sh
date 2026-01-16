#!/bin/bash

# 设置自动备份 Cron 任务
# 用法: ./scripts/setup-auto-backup.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}设置 n8n 自动备份${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 获取项目路径
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "项目路径: $PROJECT_DIR"
echo ""

# 检查脚本是否存在
if [ ! -f "$PROJECT_DIR/scripts/backup-incremental.sh" ]; then
    echo -e "${RED}✗ 备份脚本不存在${NC}"
    exit 1
fi

# 创建 cron 任务
echo -e "${YELLOW}配置 Cron 任务...${NC}"
echo ""
echo "建议的备份策略:"
echo "  1. 每周日凌晨 2 点执行完整备份"
echo "  2. 每天凌晨 3 点执行增量备份"
echo ""

# 生成 cron 配置
CRON_FULL="0 2 * * 0 cd $PROJECT_DIR && ./scripts/backup-incremental.sh full >> $PROJECT_DIR/logs/backup.log 2>&1"
CRON_INC="0 3 * * 1-6 cd $PROJECT_DIR && ./scripts/backup-incremental.sh inc >> $PROJECT_DIR/logs/backup.log 2>&1"

echo "将添加以下 Cron 任务:"
echo ""
echo "完整备份 (每周日 2:00):"
echo "  $CRON_FULL"
echo ""
echo "增量备份 (每天 3:00，周一到周六):"
echo "  $CRON_INC"
echo ""

read -p "是否继续? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

# 创建日志目录
mkdir -p "$PROJECT_DIR/logs"

# 添加到 crontab
(crontab -l 2>/dev/null || true; echo "$CRON_FULL"; echo "$CRON_INC") | crontab -

echo ""
echo -e "${GREEN}✓ Cron 任务已添加${NC}"
echo ""

# 显示当前的 crontab
echo "当前的 Cron 任务:"
crontab -l | grep -E "backup-incremental|backup\.sh" || echo "  (无相关任务)"
echo ""

# 测试备份脚本
echo -e "${YELLOW}是否立即执行一次完整备份测试? (y/N): ${NC}"
read -p "" -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}执行测试备份...${NC}"
    cd "$PROJECT_DIR"
    ./scripts/backup-incremental.sh full
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}自动备份设置完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "备份日志位置: $PROJECT_DIR/logs/backup.log"
echo "备份文件位置: $PROJECT_DIR/backups/"
echo ""
echo "查看备份日志:"
echo "  tail -f $PROJECT_DIR/logs/backup.log"
echo ""
echo "手动执行备份:"
echo "  cd $PROJECT_DIR"
echo "  ./scripts/backup-incremental.sh full    # 完整备份"
echo "  ./scripts/backup-incremental.sh inc     # 增量备份"
echo ""

