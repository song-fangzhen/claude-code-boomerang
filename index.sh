#!/bin/bash
# Claude Code notification helper script
# Uses $CLAUDE_PROJECT_DIR environment variable (set by Claude Code hooks)

# Unconditional trace log
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ENTRY: args=$* TERM_PROGRAM=$TERM_PROGRAM BUNDLE=$__CFBundleIdentifier TERM_PRODUCT=$TERM_PRODUCT" >> /tmp/boomerang_trace.log

# Hook type from first argument
hook_type="$1"

# Detect IDE and get URL scheme
detect_ide_scheme() {
  local bundle_id="$__CFBundleIdentifier"

  if [ -z "$bundle_id" ]; then
    echo "vscode://file"  # fallback
    return
  fi

  # Enable case-insensitive matching
  shopt -s nocasematch

  # Match bundle identifier patterns
  case "$bundle_id" in
    cn.trae.*)
      echo "trae-cn://file"
      ;;
    *trae*)
      echo "trae://file"
      ;;
    *vscode*)
      echo "vscode://file"
      ;;
    *todesktop*)
      echo "cursor://file"
      ;;
    *intellij*)
      echo "idea://open?file="
      ;;
    *webstorm*)
      echo "webstorm://open?file="
      ;;
    *pycharm*)
      echo "pycharm://open?file="
      ;;
    *goland*)
      echo "goland://open?file="
      ;;
    *)
      echo "vscode://file"  # fallback to vscode
      ;;
  esac

  # Restore default case sensitivity
  shopt -u nocasematch
}

ide_scheme=$(detect_ide_scheme)

# Use plugin root if available, otherwise fall back to default path
if [ -n "$CLAUDE_PLUGIN_ROOT" ]; then
  log_file="${CLAUDE_PLUGIN_ROOT}/debug.log"
else
  log_file=~/.claude/hooks/notify/debug.log
fi

# Debug log for IDE detection
debug_log() {
  if [ "$CLAUDE_NOTIFY_DEBUG" = "true" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$log_file"
  fi
}

debug_log "Detected IDE scheme: $ide_scheme (bundle: $__CFBundleIdentifier)"

# Log rotation function
log_rotate() {
  local max_lines=200
  if [ -f "$log_file" ] && [ "$CLAUDE_NOTIFY_DEBUG" = "true" ]; then
    local line_count=$(wc -l < "$log_file" 2>/dev/null || echo 0)
    if [ "$line_count" -gt $((max_lines * 2)) ]; then
      tail -n $max_lines "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
    fi
  fi
}

# Debug logging function
debug_log() {
  if [ "$CLAUDE_NOTIFY_DEBUG" = "true" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$log_file"
  fi
}

# Execute log rotation
log_rotate

debug_log "Script started, hook_type: [$hook_type], CLAUDE_PROJECT_DIR: [$CLAUDE_PROJECT_DIR]"

# Deduplication: use mkdir as atomic lock to prevent concurrent notifications
lock_path="${CLAUDE_PLUGIN_ROOT:-~/.claude/hooks/notify}/.notify_lock_dir"
# Clean up stale lock (older than 3 seconds)
if [ -d "$lock_path" ]; then
  lock_age=$(( $(date +%s) - $(stat -f %m "$lock_path" 2>/dev/null || echo 0) ))
  if [ "$lock_age" -gt 3 ]; then
    rmdir "$lock_path" 2>/dev/null
  fi
fi
# Atomic lock: mkdir only succeeds for one process
if ! mkdir "$lock_path" 2>/dev/null; then
  debug_log "SKIPPED: Dedup - another notification in progress"
  exit 0
fi
# Auto-release lock after 2 seconds
(sleep 2 && rmdir "$lock_path" 2>/dev/null) &

# 检测是否在 VSCode/Trae/Cursor 终端中执行
is_ide_terminal="false"
if [ "$TERM_PROGRAM" = "vscode" ] || [ "$TERM_PROGRAM" = "trae" ]; then
  is_ide_terminal="true"
elif [[ "$__CFBundleIdentifier" == *trae* ]]; then
  is_ide_terminal="true"
elif [ "$TERM_PRODUCT" = "Trae" ]; then
  is_ide_terminal="true"
fi

if [ "$is_ide_terminal" = "false" ]; then
  debug_log "SKIPPED: Not running in IDE terminal (TERM_PROGRAM=$TERM_PROGRAM, BUNDLE=$__CFBundleIdentifier, TERM_PRODUCT=$TERM_PRODUCT)"
  exit 0
fi

debug_log "Running in IDE terminal (TERM_PROGRAM=$TERM_PROGRAM, BUNDLE=$__CFBundleIdentifier, TERM_PRODUCT=$TERM_PRODUCT)"

# Read JSON from stdin
json=$(cat)
debug_log "JSON read completed"

# Parse tool_name from JSON if available (for PreToolUse hook)
tool_name=$(echo "$json" | osascript -l JavaScript -e "
  var json = JSON.parse(\`$json\`);
  json.tool_name || '';
" 2>/dev/null)
debug_log "tool_name: $tool_name"

# Get project name from CLAUDE_PROJECT_DIR
project_name=$(basename "$CLAUDE_PROJECT_DIR")
debug_log "project_name: $project_name"

# Check if current window is already the target VS Code window
# Use bundle identifier for precise detection (VS Code = com.microsoft.VSCode)
front_app_info=$(osascript -e '
tell application "System Events"
  set frontApp to first application process whose frontmost is true
  set appName to name of frontApp
  set bundleId to bundle identifier of frontApp
  return appName & "|" & bundleId
end tell
' 2>/dev/null)
current_app="${front_app_info%%|*}"
bundle_id="${front_app_info##*|}"
debug_log "current_app: $current_app, bundle_id: $bundle_id"

# Check if already in target window (notification will auto-dismiss)
# Match project name OR project dir components against window title
in_target_window="false"
if [ "$bundle_id" = "com.microsoft.VSCode" ] || [[ "$bundle_id" == *trae* ]]; then
  window_title=$(osascript -e "tell application \"System Events\" to get name of first window of application process \"$current_app\"" 2>/dev/null)
  debug_log "window_title: $window_title"
  if [[ "$window_title" == *"$project_name"* ]]; then
    debug_log "Already in target window, will show auto-dismiss notification"
    in_target_window="true"
  fi
fi

# Generate message and sound based on hook type
# Sounds can be customized via environment variables
case "$hook_type" in
  PreToolUse)
    if [ "$tool_name" = "ExitPlanMode" ]; then
      msg="📋 Plan Ready"
      sound="${CLAUDE_NOTIFY_SOUND_PLAN:-Hero}"
    elif [ "$tool_name" = "AskUserQuestion" ]; then
      msg="❓ Question"
      sound="${CLAUDE_NOTIFY_SOUND_QUESTION:-Glass}"
    else
      msg="⚡ Interactive Tool"
      sound="${CLAUDE_NOTIFY_SOUND_QUESTION:-Glass}"
    fi
    ;;
  Notification)
    msg="❓ Notification"
    sound="${CLAUDE_NOTIFY_SOUND_QUESTION:-Glass}"
    ;;
  Stop)
    msg="✅ Task Completed"
    sound="${CLAUDE_NOTIFY_SOUND_COMPLETE:-Ping}"
    ;;
  *)
    msg="🔔 Task Update"
    sound="${CLAUDE_NOTIFY_SOUND_DEFAULT:-default}"
    ;;
esac

debug_log "Generated message: $msg, sound: $sound"

# ============== 飞书推送 ==============
# 必须通过环境变量 CLAUDE_FEISHU_WEBHOOK 配置 Webhook URL，未配置则跳过飞书通知
FEISHU_WEBHOOK="${CLAUDE_FEISHU_WEBHOOK:-}"

send_feishu_notification() {
  if [ -z "$FEISHU_WEBHOOK" ]; then
    debug_log "SKIPPED: Feishu notification - CLAUDE_FEISHU_WEBHOOK not configured"
    return 0
  fi

  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  local current_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"

  # 根据 hook_type 选择卡片颜色
  local template_color="blue"
  case "$hook_type" in
    Stop)        template_color="green" ;;
    PreToolUse)  template_color="orange" ;;
    Notification) template_color="blue" ;;
    *)           template_color="grey" ;;
  esac

  curl -s -X POST "$FEISHU_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "{
      \"msg_type\": \"interactive\",
      \"card\": {
        \"header\": {
          \"title\": {
            \"tag\": \"plain_text\",
            \"content\": \"Claude Code - ${project_name}\"
          },
          \"template\": \"${template_color}\"
        },
        \"elements\": [
          {
            \"tag\": \"div\",
            \"text\": {
              \"tag\": \"lark_md\",
              \"content\": \"**状态**: ${msg}\n**类型**: ${hook_type}\n**项目**: ${project_name}\n**目录**: ${current_dir}\n**时间**: ${timestamp}\"
            }
          }
        ]
      }
    }" > /dev/null 2>&1
}

# 后台发送飞书通知（不阻塞桌面通知）
send_feishu_notification &
debug_log "Feishu notification sent in background"

# Run alerter in background with nohup so it survives parent process termination
nohup bash -c "
  plugin_root=\"${CLAUDE_PLUGIN_ROOT:-~/.claude/hooks/notify}\"
  log_file=\"\${plugin_root}/debug.log\"
  project_dir=\"$CLAUDE_PROJECT_DIR\"
  debug_enabled=\"$CLAUDE_NOTIFY_DEBUG\"
  ide_scheme=\"$ide_scheme\"
  sound=\"$sound\"

  # Conditional logging function
  debug_log() {
    if [ \"\$debug_enabled\" = \"true\" ]; then
      echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] \$1\" >> \"\$log_file\"
    fi
  }

  debug_log \"Running alerter with sound: \$sound\"

  # Play sound with delay so notification popup appears first
  if [ \"${CLAUDE_NOTIFY_SOUND:-on}\" != \"off\" ] && [ -n \"\$sound\" ]; then
    sound_file=\"/System/Library/Sounds/\${sound}.aiff\"
    if [ -f \"\$sound_file\" ]; then
      (sleep 0.3 && afplay \"\$sound_file\") &
    fi
  fi

  # Detect target IDE bundle ID from scheme
  if [[ \"\$ide_scheme\" == trae-cn* ]]; then
    target_bundle=\"cn.trae.app\"
  elif [[ \"\$ide_scheme\" == trae* ]]; then
    target_bundle=\"com.trae.app\"
  elif [[ \"\$ide_scheme\" == cursor* ]]; then
    target_bundle=\"com.todesktop.230313mzl4w4u92\"
  else
    target_bundle=\"com.microsoft.VSCode\"
  fi

  # Helper: check if target IDE with matching project window is frontmost
  check_in_target() {
    local fb=\$(osascript -e 'tell application \"System Events\" to get bundle identifier of first application process whose frontmost is true' 2>/dev/null)
    if [ \"\$fb\" != \"\$target_bundle\" ]; then
      return 1
    fi
    local titles=\$(osascript -e \"
      tell application \\\"System Events\\\"
        set procs to every application process whose bundle identifier is \\\"\$target_bundle\\\"
        set output to \\\"\\\"
        repeat with p in procs
          try
            repeat with w in every window of p
              set output to output & name of w & (ASCII character 10)
            end repeat
          end try
        end repeat
        return output
      end tell
    \" 2>/dev/null)
    echo \"\$titles\" | grep -q \"\$(basename \"\$project_dir\")\"
  }

  # Launch alerter (always persistent), capture output via temp file
  alerter_out=\$(mktemp)
  \"\${plugin_root}/alerter\" -group \"$project_name\" -title \"Claude Code - $project_name\" -message \"$msg\" -actions \"Open\" -closeLabel \"Dismiss\" -timeout 0 -contentImage \"\${plugin_root}/icon.png\" > \"\$alerter_out\" 2>/dev/null &
  alerter_pid=\$!
  debug_log \"Alerter launched with PID \$alerter_pid\"

  # Background monitor: poll every 2s, auto-dismiss 5s after user returns to target window
  (
    while kill -0 \$alerter_pid 2>/dev/null; do
      sleep 2
      if check_in_target; then
        debug_log \"Monitor: user in target window, starting 5s countdown\"
        sleep 5
        if check_in_target && kill -0 \$alerter_pid 2>/dev/null; then
          debug_log \"Monitor: still in target after 5s, dismissing notification\"
          kill \$alerter_pid 2>/dev/null
        fi
      fi
    done
  ) &
  monitor_pid=\$!

  # Wait for alerter to finish (user click, dismiss, or killed by monitor)
  wait \$alerter_pid 2>/dev/null
  kill \$monitor_pid 2>/dev/null
  wait \$monitor_pid 2>/dev/null
  click_result=\$(cat \"\$alerter_out\" 2>/dev/null)
  rm -f \"\$alerter_out\"

  # Debug logging
  debug_log \"Click result: [\$click_result]\"
  debug_log \"CLAUDE_PROJECT_DIR: [\$project_dir]\"

  # Open IDE if clicked
  if [ \"\$click_result\" = \"@CONTENTCLICKED\" ] || [ \"\$click_result\" = \"Open\" ]; then
    debug_log \"Condition matched, attempting to open IDE\"
    if [ -n \"\$project_dir\" ]; then
      # Build IDE URL (JetBrains uses ?file=, others use direct path)
      if [[ \"\$ide_scheme\" == *\"?file=\"* ]]; then
        ide_url=\"\${ide_scheme}\${project_dir}\"
      else
        ide_url=\"\${ide_scheme}\${project_dir}\"
      fi
      debug_log \"Opening: \$ide_url\"

      # Smart IDE window activation: prefer existing windows over opening new ones
      # Priority: exact match > parent directory match > new window
      # Determine target app bundle ID pattern based on IDE scheme
      if [[ \"\$ide_scheme\" == trae-cn* ]]; then
        app_bundle=\"cn.trae.app\"
      elif [[ \"\$ide_scheme\" == trae* ]]; then
        app_bundle=\"com.trae.app\"
      elif [[ \"\$ide_scheme\" == cursor* ]]; then
        app_bundle=\"com.todesktop.230313mzl4w4u92\"
      else
        app_bundle=\"com.microsoft.VSCode\"
      fi
      debug_log \"App bundle for window search: \$app_bundle\"

      project_basename=\$(basename \"\$project_dir\")
      activated=\$(osascript -e \"
        tell application \\\"System Events\\\"
          set ideProcs to (application processes whose bundle identifier is \\\"\$app_bundle\\\")
          if (count of ideProcs) > 0 then
            set ideProc to item 1 of ideProcs
            tell application process (name of ideProc)
              set frontmost to true
              set exactMatch to missing value
              set parentMatch to missing value

              repeat with w in windows
                set winTitle to name of w
                -- Exact match: window title contains current directory name
                if winTitle contains \\\"\$project_basename\\\" then
                  set exactMatch to w
                  exit repeat
                end if
                -- Parent directory match: project_dir contains window title as path component
                if parentMatch is missing value then
                  if \\\"\$project_dir\\\" contains (\\\"/\\\" & winTitle & \\\"/\\\") then
                    set parentMatch to w
                  end if
                end if
              end repeat

              if exactMatch is not missing value then
                perform action \\\"AXRaise\\\" of exactMatch
                return \\\"activated:exact\\\"
              else if parentMatch is not missing value then
                perform action \\\"AXRaise\\\" of parentMatch
                return \\\"activated:parent\\\"
              end if
            end tell
            return \\\"no-match\\\"
          end if
        end tell
        return \\\"not-running\\\"
      \")

      debug_log \"Window activation result: \$activated\"

      # Only use URL scheme when no matching window found
      if [[ \"\$activated\" != activated:* ]]; then
        debug_log \"No matching window, opening new: \$ide_url\"
        open \"\$ide_url\"
      fi
      debug_log \"open command completed\"
    else
      debug_log \"ERROR: CLAUDE_PROJECT_DIR is empty\"
    fi
  else
    debug_log \"No action: click_result did not match\"
  fi
  debug_log \"---\"
" > /dev/null 2>&1 &

debug_log "Notification spawned in background"
