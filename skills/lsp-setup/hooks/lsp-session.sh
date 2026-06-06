#!/bin/bash
# LSP 会话引导 hook —— SessionStart 时提醒 agent 预加载 LSP。
# 安装位置：项目 .claude/hooks/lsp-session.sh
# 配置位置：项目 .claude/settings.local.json 的 SessionStart hook
input=$(cat)
event=$(printf '%s' "$input" | jq -r '.hook_event_name // ""')

case "$event" in
  SessionStart)
    read -r -d '' ctx <<'EOF'
LSP 可用：findReferences / goToDefinition / hover / documentSymbol。需要先 ToolSearch(query: select:LSP) 预加载一次，compact 后重新加载。本会话需要 LSP 时尽量用。
EOF
    jq -n --arg ctx "$ctx" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
    ;;
esac
exit 0
