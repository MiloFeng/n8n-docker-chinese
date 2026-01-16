# 📝 n8n 工作流示例

本目录包含常见的 n8n 工作流示例，帮助您快速上手。

## 📋 示例列表

### 基础示例
- [Hello World](01-hello-world.json) - 最简单的工作流示例
- [定时任务](02-cron-job.json) - 定时执行任务
- [Webhook 触发](03-webhook.json) - 通过 HTTP 请求触发工作流

### 实用示例
- [数据处理](04-data-processing.json) - 数据转换和处理
- [API 集成](05-api-integration.json) - 调用外部 API
- [数据库操作](06-database.json) - 数据库增删改查

### 高级示例
- [错误处理](07-error-handling.json) - 错误捕获和处理
- [条件分支](08-conditional.json) - 条件判断和分支
- [循环处理](09-loop.json) - 批量数据处理

## 🚀 如何使用

### 方法一：通过 UI 导入

1. 登录 n8n (http://localhost:5678)
2. 点击右上角的 "+" 创建新工作流
3. 点击右上角的 "..." 菜单
4. 选择 "Import from File"
5. 选择示例 JSON 文件

### 方法二：通过 API 导入

```bash
# 导入工作流
curl -X POST http://localhost:5678/api/v1/workflows \
  -H "Content-Type: application/json" \
  -u admin:changeme123 \
  -d @examples/01-hello-world.json
```

### 方法三：复制粘贴

1. 打开示例 JSON 文件
2. 复制全部内容
3. 在 n8n 中点击 "Import from URL or File"
4. 粘贴 JSON 内容

## 📚 学习资源

- [n8n 官方文档](https://docs.n8n.io/)
- [n8n 社区](https://community.n8n.io/)
- [n8n 工作流模板](https://n8n.io/workflows/)

## 💡 提示

- 导入后请根据实际情况修改配置
- 某些示例需要配置凭证（如 API 密钥）
- 建议先在测试环境中运行

## 🤝 贡献

欢迎提交更多实用的工作流示例！

请确保：
- JSON 格式正确
- 包含必要的注释
- 移除敏感信息（密钥、密码等）
- 添加使用说明

---

如有问题，请查看 [故障排查文档](../TROUBLESHOOTING.md)

