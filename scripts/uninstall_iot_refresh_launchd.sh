#!/usr/bin/env bash
set -euo pipefail

LABEL="ai.xiaodu.iot-token-refresh"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"

launchctl bootout "gui/$(id -u)" "$PLIST_PATH" >/dev/null 2>&1 || true

if [[ -f "$PLIST_PATH" ]]; then
  rm "$PLIST_PATH"
fi

echo "[xiaodu-control] 已移除自动刷新任务: ${LABEL}"
