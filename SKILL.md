---
name: xiaodu-control
description: 当用户想连接、鉴权、检查、列出或控制小度智能屏 MCP 与小度 IoT MCP 时使用，包括查设备、文本播报、语音指令、拍照、资源推送、IoT 场景与家电控制，以及相关排障。
---

# xiaodu-control

以 `mcporter` 作为主接入方式。除非用户明确证明小度智能屏 MCP 和小度 IoT MCP 共享同一个端点，否则把它们当作两个独立的 server 处理。不要猜测 MCP URL，必须使用小度平台控制台里给出的真实地址。默认假设它们仍然是两个独立的 server，但通常可以复用同一个小度 MCP 平台 `ACCESS_TOKEN`。

## 工作流

1. 先确认前提条件：
   - 已安装 `mcporter`。
   - 如果要接智能屏 MCP，用户已经从平台控制台拿到了真实 HTTP MCP URL。
   - 如果要接 `xiaodu-iot`，用户已经准备好了一个可用的小度 MCP 平台 `ACCESS_TOKEN`，以及后续刷新的 `AppKey / SecretKey / refresh_token`。
   - 已知鉴权方式，是 `OAuth` 还是 `Bearer / 自定义 Header`。
   - 如果是给别人分发安装，默认按“每个安装者各自维护自己的 `~/.mcporter/` 配置和凭据”处理，不要假设会复用当前机器。
2. 在落配置前，先做一次临时探测：
   - `bash scripts/probe_xiaodu.sh --url "https://real-xiaodu-mcp-url" --name xiaodu`
   - 如果用户还要接 `xiaodu-iot`，优先先跑 `mcporter list --stdio npx --stdio-arg=-y --stdio-arg=dueros-iot-mcp --env ACCESS_TOKEN=... --name xiaodu-iot --schema` 做一次 ad-hoc 探测。
3. 只有在探测成功后再保存配置：
   - `OAuth` 方案用 `mcporter config add ... --auth oauth`，再执行 `mcporter auth <name>`。
   - `Bearer / Header` 方案优先写进 `~/.mcporter/mcporter.json`。安装、鉴权、模板和 token 刷新统一看 [references/install-for-users.md](references/install-for-users.md)。
   - `xiaodu-iot` 默认按官方 `stdio` 方案配置，不要把某台机器上的本地 runtime 当成通用默认值。
   - 如果用户是从同一个小度 MCP 应用拿到的授权结果，默认把同一个 `ACCESS_TOKEN` 同时写到 `xiaodu.headers.ACCESS_TOKEN` 和 `xiaodu-iot.env.ACCESS_TOKEN`。
4. 在写自动化或封装脚本前，先确认工具是否存在：
   - `mcporter list xiaodu --schema`
   - `mcporter list xiaodu-iot --schema`
5. 只要稳定性优先，就优先使用直接的 `mcporter call` 或本 skill 自带脚本。如果高层 skill 调用返回空结果，先回退到 CLI 直调。
6. 在做批量控制前先刷新一次设备快照：
   - `bash scripts/refresh_devices.sh --speaker-server xiaodu --iot-server xiaodu-iot`
7. 不要把密钥写进 workspace 文件或聊天记录。优先用环境变量或 mcporter 的 auth 存储。

## 执行规则

- 只要本 skill 已经提供了脚本封装，就优先调用脚本，不要直接跳到底层 MCP 工具。
- 设备相关操作如果用户只给了设备名，必须先解析出 `cuid` 和 `client_id`，再执行真实调用。
- 只要用户要控制的是家电或 IoT 设备，例如灯、空调、窗帘、电视、插座、风扇，且 `xiaodu-iot` 已配置，就必须优先走 `bash scripts/control_iot.sh` 或 `xiaodu-iot.IOT_CONTROL_DEVICES`。
- 不要把“开灯/关灯/调亮度/调温度”这类 IoT 控制请求路由到 `xiaodu.control_xiaodu`。那会变成让智能屏代发语音指令，常见表象就是智能屏自己 TTS 说一句“好的，正在关闭设备”。
- `xiaodu.control_xiaodu` 只适合智能屏自身的语音助手类任务，例如播放音乐、暂停、天气查询、新闻、百科问答，不适合作为 IoT 控制的默认路径。
- 负向测试和参数校验场景，必须优先走脚本，确保返回本地校验错误，而不是把错误留给服务端。
- 只有这几类情况可以直接用原始 `mcporter call`：
  - 读取 schema
  - 用户明确要求 direct CLI
  - 本 skill 没有对应脚本
  - 做兜底验证，证明问题在 skill 层还是在 MCP 本身

## 命令模式

- 当前已确认的智能屏 MCP 工具包括：
  - `list_user_devices`
  - `control_xiaodu`
  - `xiaodu_speak`
  - `push_resource_to_xiaodu`
  - `xiaodu_take_photo`
- IoT 侧常见工具包括：
  - `GET_ALL_DEVICES_WITH_STATUS`
  - `IOT_CONTROL_DEVICES`
  - `GET_ALL_SCENES`
  - `TRIGGER_SCENES`
- 不同部署的工具名可能有差异。任何调用前，都先用 `mcporter list <server> --schema` 确认真实名称。
- 智能屏侧除 `list_user_devices` 外，当前 live schema 都要求 `cuid` 和 `client_id`。优先按设备名解析出这两个字段，再执行真实调用。
- 当前 `IOT_CONTROL_DEVICES` 的 live schema 里，`applianceName` 是必填字段，`roomName` 只是可选限定条件，不能只传房间不传设备名。

## 自带脚本

发布到 ClawHub 后，脚本文件默认按普通文本落盘，不保证保留可执行位。命令示例里优先使用 `bash scripts/*.sh` 和 `python3 scripts/*.py`，不要假设可以直接 `./scripts/foo.sh`。

- `scripts/probe_xiaodu.sh`
  - 对真实 MCP URL 做快速连通性检查。
- `scripts/list_devices.sh`
  - 直接调用 `list_user_devices` 并输出 JSON。
- `scripts/refresh_devices.sh`
  - 拉取智能屏和 IoT 设备快照，输出 JSON 和 Markdown 摘要。
- `scripts/device_resolver.py`
  - 按设备名解析 `cuid` 和 `client_id`，供其他脚本复用。
- `scripts/speak.sh`
  - 封装 `xiaodu_speak`，用于单次文本播报。
- `scripts/control_xiaodu.sh`
  - 封装 `control_xiaodu`，用于发送语音指令。
- `scripts/push_resource.sh`
  - 封装 `push_resource_to_xiaodu`，支持图片、图片+背景音、视频、音频。
- `scripts/take_photo.sh`
  - 封装 `xiaodu_take_photo`，用于指定设备拍照。
- `scripts/control_iot.sh`
  - 封装 `IOT_CONTROL_DEVICES`，用于按房间或设备名控制。
- `scripts/list_iot_devices.sh`
  - 封装 `GET_ALL_DEVICES_WITH_STATUS`，用于读取 IoT 设备和状态。
- `scripts/list_scenes.sh`
  - 封装 `GET_ALL_SCENES`，用于读取可用场景。
- `scripts/trigger_scene.sh`
  - 封装 `TRIGGER_SCENES`，用于触发指定场景。
- `scripts/refresh_xiaodu_mcp_token.sh`
  - 用 `refresh_token` 刷新小度 MCP 平台 `ACCESS_TOKEN`，并按配置里的 `targets` 自动回写 `mcporter` 配置。默认模板会同时更新 `xiaodu` 和 `xiaodu-iot`。

## 额外入口文件

- `agents/openai.yaml`
  - 提供 OpenClaw 聊天侧的展示名、简短描述、默认提示词和隐式调用策略。
  - 这是 OpenClaw 的附加入口配置，不是运行时脚本；发布时可以保留，但要和本文件的触发语义保持一致。

## 按需阅读引用文档

- 当你要把这套 skill 分发给别人，或者指导别人从零安装、鉴权、配置 `mcporter`、配置 token 刷新时，先读 [references/install-for-users.md](references/install-for-users.md)。
- 当你要直接给用户一个可填写的安装模板时，读 [references/mcporter.template.json](references/mcporter.template.json) 和 [references/xiaodu-mcp-oauth.template.json](references/xiaodu-mcp-oauth.template.json)。
- 当你需要精确命令模板或逐工具调用方法时，读 [references/command-patterns.md](references/command-patterns.md)。
- 当你要在任意聊天渠道里直接发中文提示词时，读 [references/prompt-templates.md](references/prompt-templates.md)。
- 当你要逐项验证小度智能屏能力是否可用时，读 [references/test-cases.md](references/test-cases.md)。
- 当鉴权不稳定、列表为空，或 skill 层表现和直接 `mcporter call` 不一致时，读 [references/troubleshooting.md](references/troubleshooting.md)。
