# xiaodu-control

`xiaodu-control` 是一个面向 OpenClaw 的小度控制 skill，统一封装了：

- 小度智能屏 MCP
- 小度 IoT MCP
- 设备发现与解析
- 文本播报、语音指令、拍照、资源推送
- IoT 家电控制与场景触发
- 小度 MCP 平台 token 刷新

这个仓库是 skill 的源码仓库；实际给 OpenClaw 使用的入口文件是 [SKILL.md](./SKILL.md)。

## 能力概览

- 列出小度智能屏设备，返回设备名、在线状态、`cuid`、`client_id`
- 通过设备名解析智能屏设备，避免手工找参数
- 对智能屏执行文本播报
- 给智能屏发送语音指令，例如播放新闻、暂停、天气查询
- 调用智能屏拍照
- 给智能屏推送图片、图片+背景音、视频、音频
- 通过 `xiaodu-iot` 控制灯、空调、窗帘、电视等 IoT 设备
- 获取 IoT 设备状态、场景列表并触发场景
- 刷新小度 MCP 平台 OAuth token，并回写 `mcporter` 配置

## 适用前提

你需要至少具备下面这些条件：

- 已安装 OpenClaw
- 已安装 `mcporter`
- 已从小度平台拿到真实的智能屏 MCP 地址
- 已具备一个可用的小度 MCP 平台 `ACCESS_TOKEN`
- 如果要长期使用 IoT，还需要 `AppKey`、`SecretKey`、`refresh_token`

通常情况下，`xiaodu` 和 `xiaodu-iot` 可以复用同一个小度 MCP 平台 `ACCESS_TOKEN`。本仓库里的模板和刷新逻辑默认会把同一个 token 同时写入这两个 server。

## 快速开始

### 1. 安装 skill

如果你通过 ClawHub 安装：

```bash
clawhub install xiaodu-control
```

如果你是开发者或维护者，直接克隆本仓库即可。

### 2. 先在平台创建应用并做调试授权

第一次接入时，先去小度 MCP 控制台：

- [`https://dueros.baidu.com/dbp/mcp/console`](https://dueros.baidu.com/dbp/mcp/console)

在控制台里：

1. 创建应用
2. 进入应用详情页
3. 点击“调试授权”
4. 拿到：
   - `ACCESS_TOKEN`
   - `AppKey`
   - `SecretKey`
   - `refresh_token`

如果你接的是当前这套小度智能终端 MCP，智能屏 MCP 地址通常直接填：

```text
https://xiaodu.baidu.com/dueros_mcp_server/mcp/
```

如果控制台明确显示了其他地址，优先用平台显示值。

### 3. 配置 MCP

先按模板填写：

- [`references/mcporter.template.json`](./references/mcporter.template.json)
- [`references/xiaodu-mcp-oauth.template.json`](./references/xiaodu-mcp-oauth.template.json)

默认配置路径：

- `~/.mcporter/mcporter.json`
- `~/.mcporter/xiaodu-mcp-oauth.json`

这里要分清谁在读哪个文件：

- `~/.mcporter/mcporter.json`
  - 这是 `mcporter` 的系统配置默认路径，`mcporter list/call/auth` 会直接读取它。
- `~/.mcporter/xiaodu-mcp-oauth.json`
  - 这是这套 skill 默认使用的“小度 MCP 平台 OAuth 凭据文件”路径。
  - 它不是平台强制名称，也不是 `mcporter` 固定要求的名字；默认是刷新脚本在读取它。
  - 如果你想放在别处，也可以，只要执行刷新脚本时通过 `--config` 指到真实路径，或设置环境变量 `XIAODU_MCP_OAUTH_CONFIG=/实际路径`。

另外，OAuth 文件里的 `mcporter_config` 字段才决定“刷新后把 token 回写到哪一个 mcporter.json”。如果你的 `mcporter` 也用了自定义路径，这里要填成你的真实路径。

刷新脚本对 OAuth 凭据文件本身的默认行为是：

- 默认回写 `~/.mcporter/xiaodu-mcp-oauth.json`
- 如果新文件不存在但旧文件 `~/.mcporter/xiaodu-iot-oauth.json` 还在，会回退并写回旧文件
- 如果新旧两个默认文件都存在，会把另一份也同步，避免内容分叉
- 如果你用 `--config` 或 `XIAODU_MCP_OAUTH_CONFIG` 指了自定义路径，脚本会以你指定的那份文件为主进行回写

详细步骤见：

- [`references/install-for-users.md`](./references/install-for-users.md)

### 4. 验证本地链路

```bash
mcporter list xiaodu --schema
mcporter call xiaodu.list_user_devices --output json

mcporter list xiaodu-iot --schema
mcporter call xiaodu-iot.GET_ALL_DEVICES_WITH_STATUS --output json
```

### 5. 在 OpenClaw 中使用

第一次使用，建议显式带上 skill 名：

```text
用 $xiaodu-control 列出所有小度智能屏设备，并告诉我设备名称、在线状态、CUID 和 Client ID。
```

IoT 控制建议把链路说清楚：

```text
用 $xiaodu-control 通过 xiaodu-iot 关闭“射灯”。不要调用智能屏的 control_xiaodu。
```

更多聊天模板见：

- [`references/prompt-templates.md`](./references/prompt-templates.md)

## 常用脚本

仓库里已经带了可直接复用的脚本封装：

- `bash scripts/probe_xiaodu.sh`
- `bash scripts/list_devices.sh`
- `bash scripts/refresh_devices.sh`
- `python3 scripts/device_resolver.py`
- `bash scripts/speak.sh`
- `bash scripts/control_xiaodu.sh`
- `bash scripts/push_resource.sh`
- `bash scripts/take_photo.sh`
- `bash scripts/control_iot.sh`
- `bash scripts/list_iot_devices.sh`
- `bash scripts/list_scenes.sh`
- `bash scripts/trigger_scene.sh`
- `bash scripts/refresh_xiaodu_mcp_token.sh`

精确命令示例见：

- [`references/command-patterns.md`](./references/command-patterns.md)

## 仓库结构

```text
xiaodu-control/
├── SKILL.md
├── agents/
│   └── openai.yaml
├── references/
│   ├── install-for-users.md
│   ├── command-patterns.md
│   ├── prompt-templates.md
│   ├── test-cases.md
│   ├── troubleshooting.md
│   ├── mcporter.template.json
│   └── xiaodu-mcp-oauth.template.json
└── scripts/
    ├── *.sh
    └── *.py
```

各目录职责：

- [SKILL.md](./SKILL.md)：OpenClaw 实际读取的 skill 入口
- [`agents/openai.yaml`](./agents/openai.yaml)：OpenClaw 聊天侧展示与默认提示配置
- [`references/`](./references/)：安装、模板、命令、提示词、排障、测试文档
- [`scripts/`](./scripts/)：可复用的确定性脚本封装

## 测试与排障

- 智能屏测试清单：[`references/test-cases.md`](./references/test-cases.md)
- 常见问题排查：[`references/troubleshooting.md`](./references/troubleshooting.md)

## 发布说明

这个仓库可以有 `README.md` 供 GitHub 读者查看，但 skill 本身仍然以 [SKILL.md](./SKILL.md) 为准。

为避免把仓库说明文档一起发布到 ClawHub，仓库使用了 [`.clawhubignore`](./.clawhubignore) 排除 `README.md`。

## 安全提醒

- 不要把真实的 `ACCESS_TOKEN`、`AppKey`、`SecretKey`、`refresh_token` 提交到仓库
- 不要把本机私有路径、账号信息、测试截图、缓存文件一起发布
- 自动刷新只应写回用户本机自己的 `~/.mcporter/` 配置
