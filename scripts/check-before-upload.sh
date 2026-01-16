#!/bin/bash

# GitHub 上传前安全检查脚本

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  GitHub 上传前安全检查${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

ERRORS=0
WARNINGS=0

# 检查 .gitignore 是否存在
echo -e "${YELLOW}[1/6] 检查 .gitignore 文件...${NC}"
if [ -f ".gitignore" ]; then
    echo -e "${GREEN}✓${NC} .gitignore 文件存在"
else
    echo -e "${RED}✗${NC} .gitignore 文件不存在"
    ERRORS=$((ERRORS + 1))
fi

# 检查敏感文件是否在 .gitignore 中
echo ""
echo -e "${YELLOW}[2/6] 检查敏感文件配置...${NC}"

SENSITIVE_PATTERNS=(".env" "backups/" "n8n-local-files/" "n8n-chinese-ui/dist/" "*.pem" "*.key")

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if grep -q "$pattern" .gitignore 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $pattern 已在 .gitignore 中"
    else
        echo -e "${RED}✗${NC} $pattern 未在 .gitignore 中"
        ERRORS=$((ERRORS + 1))
    fi
done

# 检查敏感文件是否存在
echo ""
echo -e "${YELLOW}[3/6] 检查敏感文件是否存在...${NC}"

if [ -f ".env" ]; then
    echo -e "${YELLOW}⚠${NC} .env 文件存在 (确保已在 .gitignore 中)"
    WARNINGS=$((WARNINGS + 1))
fi

if [ -d "backups" ] && [ "$(ls -A backups)" ]; then
    echo -e "${YELLOW}⚠${NC} backups/ 目录不为空 (确保已在 .gitignore 中)"
    WARNINGS=$((WARNINGS + 1))
fi

if [ -d "n8n-chinese-ui/dist" ] && [ "$(ls -A n8n-chinese-ui/dist)" ]; then
    echo -e "${YELLOW}⚠${NC} n8n-chinese-ui/dist/ 目录不为空 (确保已在 .gitignore 中)"
    WARNINGS=$((WARNINGS + 1))
fi

# 检查 docker-compose.yml 中的密码
echo ""
echo -e "${YELLOW}[4/6] 检查配置文件中的密码...${NC}"

if grep -q "changeme123" docker-compose.yml; then
    echo -e "${GREEN}✓${NC} 使用示例密码 (可以上传)"
else
    echo -e "${YELLOW}⚠${NC} 密码已修改，请确认不是真实密码"
    WARNINGS=$((WARNINGS + 1))
fi

# 模拟 git status 检查
echo ""
echo -e "${YELLOW}[5/6] 检查将要提交的文件...${NC}"

if command -v git &> /dev/null; then
    if [ -d ".git" ]; then
        # 检查是否有未跟踪的敏感文件
        if git status --porcelain | grep -E "\.env$|backups/|n8n-local-files/|\.pem$|\.key$" > /dev/null; then
            echo -e "${RED}✗${NC} 发现未忽略的敏感文件:"
            git status --porcelain | grep -E "\.env$|backups/|n8n-local-files/|\.pem$|\.key$"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${GREEN}✓${NC} 未发现敏感文件"
        fi
    else
        echo -e "${YELLOW}⚠${NC} 未初始化 Git 仓库"
    fi
else
    echo -e "${YELLOW}⚠${NC} Git 未安装，跳过检查"
fi

# 检查大文件
echo ""
echo -e "${YELLOW}[6/6] 检查大文件...${NC}"

LARGE_FILES=$(find . -type f -size +10M 2>/dev/null | grep -v ".git" | grep -v "node_modules" || true)

if [ -n "$LARGE_FILES" ]; then
    echo -e "${YELLOW}⚠${NC} 发现大文件 (>10MB):"
    echo "$LARGE_FILES"
    echo "建议将这些文件添加到 .gitignore"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC} 未发现大文件"
fi

# 总结
echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  检查总结${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ 所有检查通过！可以安全上传到 GitHub${NC}"
    echo ""
    echo "建议的上传步骤:"
    echo "  git init"
    echo "  git add ."
    echo "  git commit -m 'Initial commit'"
    echo "  git remote add origin <your-repo-url>"
    echo "  git push -u origin main"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ 发现 $WARNINGS 个警告${NC}"
    echo ""
    echo "请检查警告内容，确认无误后可以上传"
else
    echo -e "${RED}✗ 发现 $ERRORS 个错误和 $WARNINGS 个警告${NC}"
    echo ""
    echo "请修复错误后再上传！"
    exit 1
fi

echo ""

