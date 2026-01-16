.PHONY: help setup start stop restart logs status backup restore clean update

# 默认配置文件
COMPOSE_FILE ?= docker-compose.yml

# 颜色输出
GREEN  := \033[0;32m
YELLOW := \033[1;33m
NC     := \033[0m

help: ## 显示帮助信息
	@echo "$(GREEN)n8n Docker 管理命令$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)使用示例:$(NC)"
	@echo "  make setup          # 快速安装"
	@echo "  make start          # 启动服务"
	@echo "  make logs           # 查看日志"
	@echo "  make backup         # 备份数据"

setup: ## 运行快速安装脚本
	@chmod +x scripts/*.sh
	@./scripts/setup.sh

start: ## 启动服务
	@echo "$(GREEN)启动 n8n 服务...$(NC)"
	@docker compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)服务已启动!$(NC)"
	@echo "访问: http://localhost:5678"

start-simple: ## 启动简化版 (SQLite)
	@echo "$(GREEN)启动 n8n 简化版...$(NC)"
	@docker compose -f docker-compose.simple.yml up -d
	@echo "$(GREEN)服务已启动!$(NC)"
	@echo "访问: http://localhost:5678"

start-ssl: ## 启动 SSL 版本
	@echo "$(GREEN)启动 n8n SSL 版本...$(NC)"
	@docker compose -f docker-compose.ssl.yml up -d
	@echo "$(GREEN)服务已启动!$(NC)"
	@echo "访问: https://localhost"

stop: ## 停止服务
	@echo "$(YELLOW)停止服务...$(NC)"
	@docker compose -f $(COMPOSE_FILE) stop
	@echo "$(GREEN)服务已停止$(NC)"

restart: ## 重启服务
	@echo "$(YELLOW)重启服务...$(NC)"
	@docker compose -f $(COMPOSE_FILE) restart
	@echo "$(GREEN)服务已重启$(NC)"

logs: ## 查看日志
	@docker compose -f $(COMPOSE_FILE) logs -f

logs-n8n: ## 查看 n8n 日志
	@docker compose -f $(COMPOSE_FILE) logs -f n8n

logs-db: ## 查看数据库日志
	@docker compose -f $(COMPOSE_FILE) logs -f postgres

status: ## 查看服务状态
	@docker compose -f $(COMPOSE_FILE) ps

stats: ## 查看资源使用情况
	@docker stats --no-stream

backup: ## 备份数据
	@chmod +x scripts/backup.sh
	@./scripts/backup.sh

restore: ## 恢复数据 (需要指定日期: make restore DATE=20240115-120000)
	@chmod +x scripts/restore.sh
	@if [ -z "$(DATE)" ]; then \
		echo "$(YELLOW)用法: make restore DATE=20240115-120000$(NC)"; \
		./scripts/restore.sh; \
	else \
		./scripts/restore.sh $(DATE); \
	fi

update: ## 更新 n8n 到最新版本
	@echo "$(YELLOW)备份数据...$(NC)"
	@make backup
	@echo "$(YELLOW)拉取最新镜像...$(NC)"
	@docker compose -f $(COMPOSE_FILE) pull
	@echo "$(YELLOW)重启服务...$(NC)"
	@docker compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)更新完成!$(NC)"

clean: ## 停止并删除容器 (保留数据卷)
	@echo "$(YELLOW)停止并删除容器...$(NC)"
	@docker compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)清理完成$(NC)"

clean-all: ## 停止并删除所有内容 (包括数据卷)
	@echo "$(YELLOW)警告: 此操作将删除所有数据!$(NC)"
	@read -p "确认继续? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		docker compose -f $(COMPOSE_FILE) down -v; \
		echo "$(GREEN)已删除所有容器和数据卷$(NC)"; \
	else \
		echo "$(YELLOW)操作已取消$(NC)"; \
	fi

shell-n8n: ## 进入 n8n 容器
	@docker compose -f $(COMPOSE_FILE) exec n8n sh

shell-db: ## 进入数据库容器
	@docker compose -f $(COMPOSE_FILE) exec postgres psql -U n8n n8n

env: ## 创建环境变量文件
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(GREEN)已创建 .env 文件,请编辑配置$(NC)"; \
	else \
		echo "$(YELLOW).env 文件已存在$(NC)"; \
	fi

ssl-cert: ## 生成自签名 SSL 证书
	@mkdir -p nginx/ssl
	@openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout nginx/ssl/key.pem \
		-out nginx/ssl/cert.pem \
		-subj "/C=CN/ST=Beijing/L=Beijing/O=Dev/CN=localhost"
	@echo "$(GREEN)SSL 证书已生成$(NC)"

test: ## 测试服务是否正常运行
	@echo "$(YELLOW)测试服务连接...$(NC)"
	@curl -f http://localhost:5678 > /dev/null 2>&1 && \
		echo "$(GREEN)✓ 服务运行正常$(NC)" || \
		echo "$(YELLOW)✗ 服务未响应$(NC)"

install-deps: ## 检查并安装依赖
	@echo "$(YELLOW)检查 Docker...$(NC)"
	@command -v docker >/dev/null 2>&1 || { echo "$(YELLOW)请安装 Docker$(NC)"; exit 1; }
	@echo "$(GREEN)✓ Docker 已安装$(NC)"
	@echo "$(YELLOW)检查 Docker Compose...$(NC)"
	@docker compose version >/dev/null 2>&1 || { echo "$(YELLOW)请安装 Docker Compose$(NC)"; exit 1; }
	@echo "$(GREEN)✓ Docker Compose 已安装$(NC)"

