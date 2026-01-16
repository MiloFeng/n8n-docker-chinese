# n8n 自定义镜像 - 预装中文 UI
# 基于官方 n8n 镜像，添加中文界面支持

ARG N8N_VERSION=latest
FROM n8nio/n8n:${N8N_VERSION}

# 维护者信息
LABEL maintainer="your-email@example.com"
LABEL description="n8n with Chinese UI pre-installed"
LABEL version="1.0.0"

# 切换到 root 用户以安装依赖
USER root

# 安装必要的工具
RUN apk add --no-cache \
    curl \
    wget \
    git \
    bash \
    jq

# 创建中文 UI 目录
RUN mkdir -p /data/n8n-chinese-ui

# 下载并安装中文 UI
ARG CHINESE_UI_VERSION=latest
RUN echo "正在下载中文 UI..." && \
    if [ "$CHINESE_UI_VERSION" = "latest" ]; then \
        DOWNLOAD_URL="https://github.com/shuangxunian/n8n-chinese/releases/latest/download/n8n-chinese.zip"; \
    else \
        DOWNLOAD_URL="https://github.com/shuangxunian/n8n-chinese/releases/download/${CHINESE_UI_VERSION}/n8n-chinese.zip"; \
    fi && \
    wget -q "$DOWNLOAD_URL" -O /tmp/n8n-chinese.zip && \
    unzip -q /tmp/n8n-chinese.zip -d /data/n8n-chinese-ui && \
    rm /tmp/n8n-chinese.zip && \
    echo "中文 UI 安装完成"

# 创建健康检查脚本
RUN echo '#!/bin/bash\n\
curl -f http://localhost:5678/healthz || exit 1' > /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

# 创建启动脚本
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "=== n8n 中文版启动 ==="\n\
echo "时区: ${TZ:-Asia/Shanghai}"\n\
echo "端口: ${N8N_PORT:-5678}"\n\
echo ""\n\
\n\
# 检查中文 UI 是否存在\n\
if [ -d "/data/n8n-chinese-ui/dist" ]; then\n\
    echo "✅ 中文 UI 已预装"\n\
    export N8N_EDITOR_BASE_URL="/data/n8n-chinese-ui/dist"\n\
else\n\
    echo "⚠️  中文 UI 未找到，使用默认界面"\n\
fi\n\
\n\
echo ""\n\
echo "正在启动 n8n..."\n\
exec n8n start' > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# 切换回 node 用户
USER node

# 设置工作目录
WORKDIR /home/node

# 暴露端口
EXPOSE 5678

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=60s \
    CMD /usr/local/bin/healthcheck.sh

# 设置入口点
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

