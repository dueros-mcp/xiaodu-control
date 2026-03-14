# xiaodu-control

`xiaodu-control` 是一个面向 OpenClaw 的小度控制 skill，统一封装了：

- 小度智能屏 MCP
- 小度 IoT MCP
- 设备发现与解析
- 文本播报、语音指令、拍照、资源推送
- IoT 家电控制与场景触发

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

## 适用前提

你需要至少具备下面这些条件：

- 已安装 OpenClaw
- 已安装 `mcporter`
- 如果要使用 `xiaodu-iot`，还需要可用的 `npx` / Node.js 运行时
- 已从小度平台拿到真实的智能屏 MCP 地址
- 已具备一个可用的小度 MCP 平台 `ACCESS_TOKEN`

通常情况下，`xiaodu` 和 `xiaodu-iot` 可以复用同一个小度 MCP 平台 `ACCESS_TOKEN`。这套公开 skill 假设 token 管理由平台侧或部署方在 skill 之外完成。

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

如果你接的是当前这套小度智能终端 MCP，智能屏 MCP 地址通常直接填：

```text
https://xiaodu.baidu.com/dueros_mcp_server/mcp/
```

如果控制台明确显示了其他地址，优先用平台显示值。

### 3. 配置 MCP

先按模板填写：

- [`references/mcporter.template.json`](./references/mcporter.template.json)

默认配置路径：

- `~/.mcporter/mcporter.json`

这里要分清角色：

- `~/.mcporter/mcporter.json`
  - 这是 `mcporter` 的系统配置默认路径，`mcporter list/call/auth` 会直接读取它。
- 这套公开 skill 只依赖已经存在的 `mcporter` 配置，不负责刷新或回写 token。
- 如果你的平台侧有 token 刷新逻辑，应在 skill 之外维护，并在 token 变化后同步更新 `mcporter.json`。

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
│   └── mcporter.template.json
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

- 不要把真实的 `ACCESS_TOKEN` 提交到仓库
- 不要把本机私有路径、账号信息、测试截图、缓存文件一起发布
- 如果平台需要自动刷新 token，请在公开 skill 之外完成
