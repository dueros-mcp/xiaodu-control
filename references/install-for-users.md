# 给其他用户的安装指南

这份文档就是这套 skill 的唯一安装文档。目标是让每个安装者在自己的 OpenClaw 环境里独立完成配置、验证和自动刷新。

## 适用场景

- 你在自己的电脑上安装了 OpenClaw
- 你想把 `xiaodu-control` 用在自己的 OpenClaw / Codex 会话里
- 你不会复用别人机器上的 `mcporter` 配置

## 你需要准备的东西

### 智能屏 MCP

- 小度智能屏 MCP 的真实 HTTP MCP URL
- 可用的 `ACCESS_TOKEN`

### 小度 IoT MCP

- `AppKey`
- `SecretKey`
- `refresh_token`
- 一个当前可用的 `ACCESS_TOKEN`

## 最短理解版

整个安装流程可以压成 5 步：

1. 从小度平台拿到智能屏 MCP 地址，以及 IoT 的 OAuth 信息
2. 按模板填写 `~/.mcporter/mcporter.json`
3. 按模板填写 `~/.mcporter/xiaodu-iot-oauth.json`
4. 用 `mcporter list` / `mcporter call` 验证本地 MCP 已跑通
5. 需要长期使用时，再安装自动刷新

## 第一步：安装 mcporter

如果还没装：

```bash
npm install -g mcporter
```

验证：

```bash
mcporter --help
```

建议先确认 `mcporter` 当前会读哪些配置源：

```bash
mcporter config list
```

正常情况下你会看到：

- 项目配置：`./config/mcporter.json`
- 系统配置：`~/.mcporter/mcporter.json`

给这套 skill 配置 server 时，推荐统一写到系统配置 `~/.mcporter/mcporter.json`。

如果你平时把 `mcporter` 或 OpenClaw 配在非默认目录，下面所有示例里的 `~/.mcporter/...` 和 `~/.openclaw/...` 都要按你的实际路径替换。

## 第二步：创建 `~/.mcporter/mcporter.json`

建议直接以这个模板为起点：

[`mcporter.template.json`](mcporter.template.json)

最小示例：

```json
{
  "mcpServers": {
    "xiaodu": {
      "baseUrl": "https://替换成你的智能屏MCP地址",
      "headers": {
        "ACCESS_TOKEN": "替换成你的智能屏ACCESS_TOKEN"
      }
    },
    "xiaodu-iot": {
      "command": "npx",
      "args": [
        "-y",
        "dueros-iot-mcp"
      ],
      "env": {
        "ACCESS_TOKEN": "替换成你的IoT ACCESS_TOKEN"
      }
    }
  }
}
```

保存到：

```text
~/.mcporter/mcporter.json
```

如果你不想手动编辑 JSON，也可以直接用命令写入：

```bash
mcporter config add xiaodu \
  --url "https://替换成你的智能屏MCP地址" \
  --header "ACCESS_TOKEN=替换成你的智能屏ACCESS_TOKEN" \
  --persist ~/.mcporter/mcporter.json

mcporter config add xiaodu-iot \
  --command npx \
  --arg -y \
  --arg dueros-iot-mcp \
  --env "ACCESS_TOKEN=替换成你的IoT ACCESS_TOKEN" \
  --persist ~/.mcporter/mcporter.json
```

## 第三步：创建 IoT OAuth 凭据文件

建议直接以这个模板为起点：

[`xiaodu-iot-oauth.template.json`](xiaodu-iot-oauth.template.json)

最小示例：

```json
{
  "token_endpoint": "https://openapi.baidu.com/oauth/2.0/token",
  "client_id": "替换成你的AppKey",
  "client_secret": "替换成你的SecretKey",
  "refresh_token": "替换成你当前最新的refresh_token",
  "scope": "basic dueros",
  "mcporter_config": "~/.mcporter/mcporter.json",
  "targets": [
    {
      "server": "xiaodu-iot",
      "container": "env",
      "key": "ACCESS_TOKEN"
    }
  ]
}
```

保存到：

```text
~/.mcporter/xiaodu-iot-oauth.json
```

建议权限：

```bash
chmod 600 ~/.mcporter/mcporter.json ~/.mcporter/xiaodu-iot-oauth.json
```

这里有一个很重要的边界：

- `xiaodu-control` skill 可以分发
- 但 `AppKey / SecretKey / refresh_token / ACCESS_TOKEN` 不能跟 skill 一起公开分发

每个安装者都必须在自己的机器上填写自己的值。

## 第四步：验证配置

### 验证智能屏 MCP

```bash
mcporter list xiaodu --schema
mcporter call xiaodu.list_user_devices --output json
```

### 验证 IoT MCP

```bash
mcporter list xiaodu-iot --schema
mcporter call xiaodu-iot.GET_ALL_DEVICES_WITH_STATUS --output json
```

## 第五步：安装自动刷新

先明确原则：

- 如果你是“自己机器上自己用”，就在自己的机器上装自动刷新
- 如果你们多人共用同一个 OpenClaw / Gateway 主机，只需要那台主机装一次自动刷新
- 如果每个人都各自安装 OpenClaw，就每个人各自装自己的自动刷新

### macOS

```bash
cd ~/.openclaw/skills/xiaodu-control
bash ./scripts/install_iot_refresh_launchd.sh --refresh-if-within-days 7
```

### Linux

本 skill 目前没有直接提供 `systemd` 或 `cron` 安装脚本。最简单的方式是每天执行一次：

```bash
bash ~/.openclaw/skills/xiaodu-control/scripts/refresh_iot_token.sh --refresh-if-within-days 7
```

可以把这条命令接到你自己的 `cron` 或 `systemd timer`。

### Windows

当前没有直接提供 Task Scheduler 安装脚本。建议把下面这条命令接到计划任务：

```text
python %USERPROFILE%\.openclaw\skills\xiaodu-control\scripts\refresh_baidu_access_token.py --config %USERPROFILE%\.mcporter\xiaodu-iot-oauth.json --refresh-if-within-days 7
```

## 第六步：刷新后的验证

每次自动刷新或手动刷新后，都可以用这两条验证：

```bash
mcporter list xiaodu-iot --schema
mcporter call xiaodu-iot.GET_ALL_DEVICES_WITH_STATUS --output json
```

## 常见边界

- `xiaodu` 智能屏 MCP 走 HTTP MCP
- `xiaodu-iot` 走官方 `dueros-iot-mcp` 的 stdio server
- 如果 `npx -y dueros-iot-mcp` 首次启动很慢，先耐心等一次；如果握手仍然超时，再看 [`troubleshooting.md`](troubleshooting.md)
- 如果 `refresh_token` 成功刷新过一次，必须保存新返回的 `refresh_token`
- 不要把 `AppKey / SecretKey / refresh_token` 跟 skill 一起公开分发
