#!/usr/bin/env bash

# Update the current Kitty tab from Codex/Claude lifecycle hook input.
# Hook commands receive one JSON object on stdin and must never disturb the
# agent when Kitty is unavailable, so every failure here is intentionally soft.

set -uo pipefail

payload="$(cat 2>/dev/null)" || payload="{}"
requested_state="${1:-auto}"
agent="${2:-codex}"

json_value() {
  jq -r "$1 // empty" <<< "$payload" 2>/dev/null
}

question_at_end() {
  local message="$1" last_block
  last_block="$(awk -v RS='' 'NF { block=$0 } END { print block }' <<< "$message")"
  [[ "$last_block" == *"?"* ]]
}

resolve_state() {
  local event notification tool message

  if [[ "$requested_state" != "auto" ]]; then
    printf '%s\n' "$requested_state"
    return 0
  fi

  event="$(json_value '.hook_event_name')"
  case "$event" in
    SessionStart)
      # /clear and /new start a fresh conversation (source "clear"); drop the
      # tab title entirely instead of marking the stale one as ready.
      case "$(json_value '.source')" in
        clear|new) printf 'clear\n' ;;
        *) printf 'ready\n' ;;
      esac
      ;;
    UserPromptSubmit)
      printf 'working\n'
      ;;
    PermissionRequest)
      printf 'input\n'
      ;;
    PreToolUse)
      tool="$(json_value '.tool_name')"
      case "$tool" in
        AskUserQuestion|request_user_input) printf 'input\n' ;;
        *) printf 'working\n' ;;
      esac
      ;;
    PostToolUse)
      # Interactive answers do not consistently emit UserPromptSubmit. Any
      # completed tool event means the agent has resumed after user input.
      printf 'working\n'
      ;;
    Notification)
      notification="$(json_value '.notification_type')"
      case "$notification" in
        permission_prompt|elicitation_dialog|elicitation_url_dialog|agent_needs_input)
          printf 'input\n'
          ;;
        idle_prompt|agent_completed)
          printf 'ready\n'
          ;;
        *) return 1 ;;
      esac
      ;;
    Stop)
      message="$(json_value '.last_assistant_message')"
      if question_at_end "$message"; then
        printf 'input\n'
      else
        printf 'ready\n'
      fi
      ;;
    SessionEnd)
      printf 'ready\n'
      ;;
    *)
      return 1
      ;;
  esac
}

strip_state_prefix() {
  local title="$1" previous=""
  while [[ "$title" != "$previous" ]]; do
    previous="$title"
    title="${title#▶ Working · }"
    title="${title#\? Needs input · }"
    title="${title#○ Ready · }"
    title="${title#▶ }"
    title="${title#\? }"
    title="${title#✓ }"
    title="${title#◆ }"
    title="${title#⁇ }"
    title="${title#◇ }"
  done
  printf '%s' "$title"
}

emit_hook_result() {
  # Empty JSON is valid for both Codex and Claude lifecycle command hooks.
  printf '{}\n'
}

state="$(resolve_state)" || {
  emit_hook_result
  exit 0
}

window_id="${KITTY_WINDOW_ID:-}"
kitty_address="${KITTY_LISTEN_ON:-}"
if [[ ! "$window_id" =~ ^[0-9]+$ || -z "$kitty_address" ]]; then
  emit_hook_result
  exit 0
fi

if [[ "$state" == "clear" ]]; then
  # Freshly cleared conversation: label the tab "new" (a manual override)
  # until the next event rebuilds a real title.
  kitten @ --to "$kitty_address" set-tab-title \
    --match "window_id:$window_id" "new" >/dev/null 2>&1 || true
  emit_hook_result
  exit 0
fi

kitty_state="$(kitten @ --to "$kitty_address" ls 2>/dev/null)" || kitty_state=""
current_title="$(
  jq -r --argjson window_id "$window_id" '
    first(
      .[]?.tabs[]?
      | select(any(.windows[]?; .id == $window_id))
      | .title
    ) // empty
  ' <<< "$kitty_state" 2>/dev/null
)"

base_title="$(strip_state_prefix "$current_title")"
base_title="${base_title//$'\n'/ }"
base_title="${base_title//$'\r'/ }"
[[ -n "$base_title" ]] || base_title="Agent · ${PWD##*/}"

case "$agent:$state" in
  codex:working) title="▶ $base_title" ;;
  codex:input) title="? $base_title" ;;
  codex:ready) title="✓ $base_title" ;;
  claude:working) title="◆ $base_title" ;;
  claude:input) title="⁇ $base_title" ;;
  claude:ready) title="◇ $base_title" ;;
  *)
    emit_hook_result
    exit 0
    ;;
esac

kitten @ --to "$kitty_address" set-tab-title \
  --match "window_id:$window_id" "$title" >/dev/null 2>&1 || true

emit_hook_result
