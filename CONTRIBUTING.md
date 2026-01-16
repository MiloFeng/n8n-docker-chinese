# 🤝 贡献指南

感谢您对本项目的关注！我们欢迎任何形式的贡献。

## 📋 目录

- [行为准则](#行为准则)
- [如何贡献](#如何贡献)
- [开发流程](#开发流程)
- [提交规范](#提交规范)
- [问题反馈](#问题反馈)

## 🌟 行为准则

参与本项目即表示您同意遵守我们的行为准则。请保持友善、尊重和包容。

## 💡 如何贡献

### 报告 Bug

如果您发现了 Bug，请：

1. 检查 [Issues](../../issues) 确认问题未被报告
2. 使用 Bug 报告模板创建新 Issue
3. 提供详细的重现步骤和环境信息
4. 如果可能，提供错误日志和截图

### 建议新功能

如果您有功能建议，请：

1. 检查 [Issues](../../issues) 确认功能未被提出
2. 使用功能请求模板创建新 Issue
3. 详细描述功能的用途和价值
4. 如果可能，提供实现思路

### 提交代码

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的变更 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 🔧 开发流程

### 环境准备

```bash
# 克隆仓库
git clone https://github.com/your-username/n8n-docker.git
cd n8n-docker

# 安装依赖
# 本项目主要是配置文件，无需安装依赖

# 启动开发环境
docker compose up -d
```

### 测试变更

```bash
# 测试 docker-compose 配置
docker compose config

# 启动服务
docker compose up -d

# 查看日志
docker compose logs -f

# 健康检查
docker compose ps
```

### 文档更新

如果您的变更涉及：
- 新功能：更新 README.md
- 配置变更：更新相关文档
- Bug 修复：更新 TROUBLESHOOTING.md
- 中文支持：更新 中文配置.md

## 📝 提交规范

### Commit Message 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式化
- `refactor`: 重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建/工具变更

### 示例

```
feat(docker): 添加健康检查配置

为所有 docker-compose 文件添加健康检查配置，
提高服务可靠性和监控能力。

Closes #123
```

## 🐛 问题反馈

### 提问前

请先查看：
- [README.md](README.md) - 项目介绍和快速开始
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 故障排查
- [中文配置.md](中文配置.md) - 中文界面配置
- [PERFORMANCE.md](PERFORMANCE.md) - 性能优化

### 提问时

请提供：
- 详细的问题描述
- 重现步骤
- 环境信息（操作系统、Docker 版本等）
- 相关日志和错误信息
- 您已经尝试的解决方法

## 🎯 优先级

我们优先处理：

1. **P0 - 紧急**: 安全问题、数据丢失、服务崩溃
2. **P1 - 高**: 功能异常、性能问题
3. **P2 - 中**: 功能改进、文档完善
4. **P3 - 低**: 优化建议、新功能

## 📞 联系方式

- 提交 Issue: [GitHub Issues](../../issues)
- 讨论区: [GitHub Discussions](../../discussions)

## 🙏 致谢

感谢所有贡献者的付出！

---

再次感谢您的贡献！ ❤️

