#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
用法:
  install_iot_refresh_launchd.sh [--config 凭据文件] [--refresh-if-within-days 天数] [--start-interval 秒数]

示例:
  install_iot_refresh_launchd.sh
  install_iot_refresh_launchd.sh --refresh-if-within-days 7
  install_iot_refresh_launchd.sh --config ~/.mcporter/xiaodu-iot-oauth.json --start-interval 86400
EOF
}

CONFIG="$HOME/.mcporter/xiaodu-iot-oauth.json"
REFRESH_IF_WITHIN_DAYS="7"
START_INTERVAL="86400"
LABEL="ai.xiaodu.iot-token-refresh"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNNER="$SCRIPT_DIR/refresh_iot_token.sh"
LOG_DIR="$HOME/Library/Logs"
STDOUT_LOG="$LOG_DIR/xiaodu-iot-token-refresh.log"
STDERR_LOG="$LOG_DIR/xiaodu-iot-token-refresh.err.log"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      CONFIG="${2:-}"
      shift 2
      ;;
    --refresh-if-within-days)
      REFRESH_IF_WITHIN_DAYS="${2:-}"
      shift 2
      ;;
    --start-interval)
      START_INTERVAL="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

mkdir -p "$HOME/Library/LaunchAgents" "$LOG_DIR"

cat >"$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${RUNNER}</string>
    <string>--config</string>
    <string>${CONFIG}</string>
    <string>--refresh-if-within-days</string>
    <string>${REFRESH_IF_WITHIN_DAYS}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>${START_INTERVAL}</integer>
  <key>StandardOutPath</key>
  <string>${STDOUT_LOG}</string>
  <key>StandardErrorPath</key>
  <string>${STDERR_LOG}</string>
  <key>WorkingDirectory</key>
  <string>${HOME}</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)" "$PLIST_PATH" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"
launchctl enable "gui/$(id -u)/${LABEL}" >/dev/null 2>&1 || true
launchctl kickstart -k "gui/$(id -u)/${LABEL}" >/dev/null 2>&1 || true

echo "[xiaodu-control] 已安装自动刷新任务"
echo "[xiaodu-control] Label: ${LABEL}"
echo "[xiaodu-control] Plist: ${PLIST_PATH}"
echo "[xiaodu-control] 日志:"
echo "  - ${STDOUT_LOG}"
echo "  - ${STDERR_LOG}"
echo "[xiaodu-control] 检查频率: 每 ${START_INTERVAL} 秒检查一次"
echo "[xiaodu-control] 刷新条件: token 剩余 ${REFRESH_IF_WITHIN_DAYS} 天内过期才刷新"
