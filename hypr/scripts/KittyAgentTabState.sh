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

# Background work tracking. A turn can end (Stop) while subagents are still
# running, and the tab must keep the working marker instead of claiming the
# agent is idle. One file per live agent, keyed by session.
agent_state_dir() {
  local sid
  sid="$(json_value '.session_id')"
  [[ -n "$sid" ]] || sid="win-${KITTY_WINDOW_ID:-unknown}"
  printf '%s/ado-kitty-agents/%s' "${XDG_RUNTIME_DIR:-/tmp}" "${sid//[^A-Za-z0-9_-]/_}"
}

agent_token() {
  local id
  id="$(json_value '.agent_id')"
  [[ -n "$id" ]] || id="anon"
  printf '%s' "${id//[^A-Za-z0-9_-]/_}"
}

mark_agent_running() {
  local dir
  dir="$(agent_state_dir)" || return 0
  mkdir -p "$dir" 2>/dev/null && : >"$dir/$(agent_token)" 2>/dev/null
}

mark_agent_done() {
  local dir
  dir="$(agent_state_dir)"
  rm -f "$dir/$(agent_token)" 2>/dev/null
  rmdir "$dir" 2>/dev/null
}

forget_agents() { rm -rf -- "$(agent_state_dir)" 2>/dev/null; }

agents_running() {
  local dir
  dir="$(agent_state_dir)"
  [[ -d "$dir" ]] || return 1
  # A crashed agent never sends SubagentStop, so ignore stale entries rather
  # than pinning the tab on "working" forever.
  find "$dir" -type f -mmin +240 -delete 2>/dev/null
  [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]
}

question_at_end() {
  local message="$1" last_line
  # Only a CLOSING question means the agent is waiting on an answer. Scanning
  # the whole trailing paragraph for "?" flagged tabs for any incidental
  # question mark ("did that work? Anyway, all done.", a "?" glob in prose),
  # so test the last non-empty line instead.
  last_line="$(awk 'NF { line = $0 } END { print line }' <<< "$message")"
  last_line="${last_line%"${last_line##*[![:space:]]}"}"
  # Peel trailing markdown wrappers so "**Shall I continue?**" still counts.
  # Quoted case patterns, not a regex bracket class: an escaped "]" closes the
  # class early and the whole test silently stops matching.
  while [[ -n "$last_line" ]]; do
    case "$last_line" in
      *'*' | *'_' | *'`' | *'"' | *"'" | *')' | *']' | *'>')
        last_line="${last_line%?}"
        last_line="${last_line%"${last_line##*[![:space:]]}"}"
        ;;
      *) break ;;
    esac
  done
  [[ "$last_line" == *"?" ]]
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
      forget_agents
      # /clear and /new start a fresh conversation (source "clear"); drop the
      # tab title entirely instead of marking the stale one as ready.
      case "$(json_value '.source')" in
        clear|new) printf 'clear\n' ;;
        *) printf 'ready\n' ;;
      esac
      ;;
    SubagentStart)
      mark_agent_running
      printf 'working\n'
      ;;
    SubagentStop)
      # The parent turn resumes once a subagent returns, so this is still work.
      mark_agent_done
      printf 'working\n'
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
        agent_completed)
          printf 'ready\n'
          ;;
        idle_prompt)
          # Timer-driven nag, not a state change: leave the title alone so an
          # idle session keeps whatever it was last labelled.
          return 1
          ;;
        *) return 1 ;;
      esac
      ;;
    Stop)
      # Subagents outlive the turn that spawned them: keep the working marker
      # rather than claiming the tab is idle.
      if agents_running; then
        printf 'working\n'
        return 0
      fi
      message="$(json_value '.last_assistant_message')"
      if question_at_end "$message"; then
        printf 'input\n'
      else
        printf 'ready\n'
      fi
      ;;
    SessionEnd)
      forget_agents
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

if [[ "$agent" == "preserve" ]]; then
  case "$current_title" in
    "◆ "*|"⁇ "*|"◇ "*) agent="claude" ;;
    "▶ "*|"? "*|"✓ "*) agent="codex" ;;
    *)
      # Ctrl+C/Escape in an ordinary shell must not create an agent marker.
      emit_hook_result
      exit 0
      ;;
  esac
fi

base_title="$(strip_state_prefix "$current_title")"
base_title="${base_title//$'\n'/ }"
base_title="${base_title//$'\r'/ }"
# Trim whitespace, and treat the transient "new" label set on /clear as
# empty, so the next event regenerates a fresh name instead of keeping it.
base_title="${base_title#"${base_title%%[![:space:]]*}"}"
base_title="${base_title%"${base_title##*[![:space:]]}"}"
[[ "$base_title" == "new" ]] && base_title=""
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
