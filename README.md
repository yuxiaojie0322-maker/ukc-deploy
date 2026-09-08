# Unikraft Cloud 多区域部署 (x-tunnel 微内核版)

自动化部署 x-tunnel (带 smux 多路复用) 到 Unikraft Cloud 的 5 个区域：`fra` / `was` / `dal` / `sin` / `sfo`。

## 特性
- **全自动 CI/CD 构建**：GitHub Actions 自动编译 Go 源码为极小 unikernel 镜像并推送到 Unikraft 官方仓库。
- **5 大区域多活**：自动分发部署到全球 5 个节点。
- **多路复用加速**：支持 smux 多路复用，搭配 Windows 客户端优选 IP/域名极速连接。

## 快速开始

### 1. 配置 GitHub Secrets
在仓库 `Settings` -> `Secrets and variables` -> `Actions` 中添加：
- `UKC_TOKEN`: Unikraft Cloud API Token (在 console.unikraft.cloud 获取)
- `TG_BOT_TOKEN` *(可选)*: Telegram Bot Token
- `TG_CHAT_ID` *(可选)*: Telegram 接收通知的用户/群组 ID

### 2. 触发部署
- **自动触发**：推送代码到 `main` 分支自动编译并部署。
- **手动触发**：在 GitHub 的 `Actions` 标签页，选择 `ukc-deploy` -> `Run workflow`，操作选择 `build-and-deploy` 即可。

### 3. Windows 客户端连接
部署完成后，GitHub Actions 摘要会显示各节点的 FQDN 域名，使用本地 `x-tunnel-windows-amd64.exe`：
```powershell
.\x-tunnel-windows-amd64.exe -l socks5://127.0.0.1:1080 -f wss://<节点域名>:443/ -token "694949f5-54c3-4113-b3c9-2d2518f770f4" -ip "优选IP/域名列表"
```
