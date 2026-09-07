# Unikraft Cloud 多区域部署

自动化部署应用到 Unikraft Cloud 的 5 个 metro：`fra` / `was` / `dal` / `sin` / `sfo`

## 快速开始

### 1. 获取 API Token

1. 登录 [unikraft.cloud](https://unikraft.cloud)
2. 打开浏览器 DevTools → Application → Cookies → `console.unikraft.cloud`
3. 复制 `ukc_auth` 的值

### 2. 配置 GitHub Secrets

在 repo → Settings → Secrets and variables → Actions 添加：

| Secret | 说明 | 示例 |
|--------|------|------|
| `UKC_TOKEN` | Unikraft API token | `MTc4ODc2...` |
| `TG_BOT_TOKEN` | Telegram Bot Token | `123456:ABC-DEF...` |
| `TG_CHAT_ID` | Telegram Chat ID | `123456789` |

### 3. 触发部署

- **手动**：Actions tab → `ukc-deploy` → Run workflow
- **定时**：每天北京时间 09:00 自动执行

## 部署配置

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `image` | `nginx:latest` | Docker 镜像 |
| `memory` | `128Mi` | 内存配额 |
| `metros` | `fra,was,dal,sin,sfo` | 逗号分隔的 metro 列表 |

## 资源规格

- 每个实例：`1 vCPU` / `128MiB` 内存
- 启用 `scale-to-zero`（零请求时自动休眠）
- 冷却时间：1000ms
- 暴露端口：`443:8080/http+tls` + `80:8080/http`

## 访问地址

部署成功后每个实例获得 `*.run.unikraft.cloud` 域名：
- `https://ukc-fra-xxxx.run.unikraft.cloud`
- `https://ukc-sin-xxxx.run.unikraft.cloud`

## Telegram 推送

每次部署推送消息到指定 Chat ID，包含：
- 每个 metro 的部署状态
- 实例 FQDN
- 冒烟测试结果
