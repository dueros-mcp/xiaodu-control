# 用户的安装指南

这份文档就是这套公开 skill 的安装文档。目标是让每个安装者在自己的 OpenClaw 环境里完成 `mcporter` 配置和验证，然后直接使用控制能力。

## 适用场景

- 你在自己的电脑上安装了 OpenClaw
- 你想把 `xiaodu-control` 用在自己的 OpenClaw 会话里
- 你不会复用别人机器上的 `mcporter` 配置

## 你需要准备的东西

- 可用的 `mcporter`
- 如果要使用 `xiaodu-iot`，还需要可用的 `npx` / Node.js 运行时

### 智能屏 MCP

- 小度智能屏 MCP 的真实 HTTP MCP URL
- 可用的 `ACCESS_TOKEN`

## 最短理解版

整个安装流程可以压成 4 步：

1. 先到小度 MCP 控制台创建应用，并完成调试授权
2. 按模板填写 `~/.mcporter/mcporter.json`
3. 用 `mcporter list` / `mcporter call` 验证本地 MCP 已跑通
4. 在 OpenClaw 里调用 `xiaodu-control`

通常情况下，`xiaodu` 和 `xiaodu-iot` 可以复用同一个小度 MCP 平台 `ACCESS_TOKEN`。这份公开 skill 默认按“同一个 token 同时配置到两个 server”处理。

## 第零步：先在平台创建应用并完成调试授权

第一次接入时，不要先改本地文件，先去平台把信息拿齐。

### 入口

- 小度 MCP 控制台：[`https://dueros.baidu.com/dbp/mcp/console`](https://dueros.baidu.com/dbp/mcp/console)

### 你需要在平台做的事

1. 登录控制台
2. 创建你自己的小度 MCP 应用
3. 打开应用详情页
4. 点击“调试授权”
5. 记录下面这些信息

### 你要从平台拿到什么

- 平台 `ACCESS_TOKEN`
- 智能屏 MCP 地址

### 关于智能屏 MCP 地址

如果你接的是当前这套小度智能终端 MCP，实际接入时通常使用：

```text
https://xiaodu.baidu.com/dueros_mcp_server/mcp/
```

这是基于当前平台接入和现有实测整理出的常用地址。  
如果你在控制台或官方说明里看到了平台明确给出的地址，优先以平台显示为准。

### 调试授权拿到的值怎么用

- `ACCESS_TOKEN`
  - 直接写进 `mcporter.json`
  - 默认同时给 `xiaodu` 和 `xiaodu-iot` 用

## 第一步：安装 mcporter

如果还没装：

```bash
npm install -g mcporter
```

验证：

```bash
mcporter --help
```

如果你要使用 `xiaodu-iot`，再确认 `npx` 可用：

```bash
npx --help
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
        "ACCESS_TOKEN": "替换成你的小度MCP平台ACCESS_TOKEN"
      }
    },
    "xiaodu-iot": {
      "command": "npx",
      "args": [
        "-y",
        "dueros-iot-mcp"
      ],
      "env": {
        "ACCESS_TOKEN": "替换成你的小度MCP平台ACCESS_TOKEN"
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
  --header "ACCESS_TOKEN=替换成你的小度MCP平台ACCESS_TOKEN" \
  --persist ~/.mcporter/mcporter.json

mcporter config add xiaodu-iot \
  --command npx \
  --arg -y \
  --arg dueros-iot-mcp \
  --env "ACCESS_TOKEN=替换成你的小度MCP平台ACCESS_TOKEN" \
  --persist ~/.mcporter/mcporter.json
```

## 第三步：验证配置

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

## 第四步：在 OpenClaw 中使用

第一次使用，建议显式带上 skill 名：

```text
用 $xiaodu-control 列出所有小度智能屏设备，并告诉我设备名称、在线状态、CUID 和 Client ID。
```

IoT 控制建议把链路说清楚：

```text
用 $xiaodu-control 通过 xiaodu-iot 关闭“射灯”。不要调用智能屏的 control_xiaodu。
```

## 常见边界

- `xiaodu` 智能屏 MCP 走 HTTP MCP
- `xiaodu-iot` 走官方 `dueros-iot-mcp` 的 stdio server
- 两个 server 虽然配置形式不同，但通常可以复用同一个小度 MCP 平台 `ACCESS_TOKEN`
- 如果 `npx -y dueros-iot-mcp` 首次启动很慢，先耐心等一次；如果握手仍然超时，再看 [`troubleshooting.md`](troubleshooting.md)
- 如果 token 已过期，这套公开 skill 不会自动刷新；应由平台侧或部署方在 skill 之外更新 `mcporter` 配置
