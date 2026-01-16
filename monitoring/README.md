# 📊 n8n 监控告警系统

基于 Prometheus + Grafana 的完整监控解决方案。

## 🎯 功能特性

### 监控指标
- ✅ **n8n 应用指标**
  - 工作流执行次数
  - 工作流成功/失败率
  - 执行时间统计
  - API 请求统计

- ✅ **系统指标**
  - CPU 使用率
  - 内存使用率
  - 磁盘使用率
  - 网络流量

- ✅ **容器指标**
  - 容器 CPU/内存使用
  - 容器重启次数
  - 容器网络流量

- ✅ **数据库指标**
  - PostgreSQL 连接数
  - 查询性能
  - 数据库大小

### 告警规则
- 🚨 n8n 服务宕机
- 🚨 工作流失败率过高
- 🚨 数据库连接失败
- 🚨 CPU/内存使用率过高
- 🚨 磁盘空间不足
- 🚨 容器频繁重启

## 🚀 快速开始

### 1. 启动监控服务

```bash
# 使用监控版 docker-compose
docker compose -f docker-compose.monitoring.yml up -d

# 查看服务状态
docker compose -f docker-compose.monitoring.yml ps
```

### 2. 访问监控面板

- **Grafana**: http://localhost:3000
  - 默认用户名: `admin`
  - 默认密码: `admin` (首次登录需修改)

- **Prometheus**: http://localhost:9090
  - 查看指标和告警规则

### 3. 配置 Grafana

首次登录后：
1. 修改默认密码
2. 数据源已自动配置 (Prometheus)
3. 导入仪表板 (可选)

## 📈 推荐仪表板

### 官方仪表板 ID
可以从 Grafana 官网导入以下仪表板：

- **Node Exporter Full**: 1860
- **Docker Container & Host Metrics**: 10619
- **PostgreSQL Database**: 9628

### 导入方法
1. 登录 Grafana
2. 点击 "+" → "Import"
3. 输入仪表板 ID
4. 选择 Prometheus 数据源
5. 点击 "Import"

## ⚙️ 配置说明

### Prometheus 配置

配置文件: `monitoring/prometheus/prometheus.yml`

```yaml
# 修改抓取间隔
global:
  scrape_interval: 15s  # 默认 15 秒

# 添加新的监控目标
scrape_configs:
  - job_name: 'my-service'
    static_configs:
      - targets: ['my-service:port']
```

### 告警规则

配置文件: `monitoring/prometheus/alerts.yml`

```yaml
# 添加自定义告警规则
groups:
  - name: custom_alerts
    rules:
      - alert: MyAlert
        expr: my_metric > threshold
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "告警摘要"
          description: "告警详情"
```

### Grafana 配置

环境变量配置 (在 `.env` 文件中):

```bash
# Grafana 管理员账号
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your-secure-password
```

## 📊 自定义仪表板

### 创建新仪表板

1. 登录 Grafana
2. 点击 "+" → "Dashboard"
3. 添加面板
4. 选择 Prometheus 数据源
5. 编写 PromQL 查询

### 常用 PromQL 查询

```promql
# n8n 工作流执行总数
sum(n8n_workflow_executions_total)

# 工作流成功率
sum(rate(n8n_workflow_success_total[5m])) / sum(rate(n8n_workflow_executions_total[5m])) * 100

# CPU 使用率
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 内存使用率
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# 容器内存使用
container_memory_usage_bytes{name=~"n8n.*"}
```

## 🔔 告警通知

### 配置 Alertmanager (可选)

1. 创建 `alertmanager.yml` 配置文件
2. 配置通知渠道 (邮件、Slack、钉钉等)
3. 在 `docker-compose.monitoring.yml` 中添加 Alertmanager 服务
4. 更新 Prometheus 配置

示例配置:

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m

route:
  receiver: 'default'
  group_by: ['alertname', 'severity']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h

receivers:
  - name: 'default'
    email_configs:
      - to: 'your-email@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.example.com:587'
        auth_username: 'alertmanager@example.com'
        auth_password: 'password'
```

## 🛠️ 故障排查

### Prometheus 无法抓取指标

```bash
# 检查 Prometheus 日志
docker logs n8n-prometheus

# 检查目标状态
# 访问 http://localhost:9090/targets
```

### Grafana 无法连接数据源

```bash
# 检查 Grafana 日志
docker logs n8n-grafana

# 检查网络连接
docker exec n8n-grafana ping prometheus
```

### 告警不触发

```bash
# 检查告警规则
# 访问 http://localhost:9090/alerts

# 验证 PromQL 查询
# 在 Prometheus 中手动执行查询
```

## 📝 最佳实践

1. **定期备份 Grafana 配置**
   ```bash
   docker exec n8n-grafana grafana-cli admin export-dashboard > backup.json
   ```

2. **监控数据保留策略**
   - 默认保留 30 天
   - 可在 Prometheus 启动参数中修改

3. **告警规则优化**
   - 避免告警风暴
   - 设置合理的阈值
   - 使用告警分组

4. **性能优化**
   - 调整抓取间隔
   - 限制指标数量
   - 使用记录规则

## 🔗 相关资源

- [Prometheus 官方文档](https://prometheus.io/docs/)
- [Grafana 官方文档](https://grafana.com/docs/)
- [PromQL 查询语言](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana 仪表板市场](https://grafana.com/grafana/dashboards/)

---

如有问题，请查看 [故障排查文档](../TROUBLESHOOTING.md)

