#!/usr/bin/env bash

# Persist Kitty tabs as a startup session. Agent tabs are stored as resume
# commands, so closing Kitty really stops them while keeping their thread IDs.

set -uo pipefail

session_file="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/ado-session.conf"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
save_lock="$runtime_dir/ado-kitty-session-save.lock"
watch_lock="$runtime_dir/ado-kitty-session-watch.lock"
# Keep close-time saves immediate; the background watcher snapshots twice an hour.
watch_interval_seconds=1800
mode="save"
requested_pid=""

while (($#)); do
  case "$1" in
    --save) mode="save" ;;
    --watch) mode="watch" ;;
    --pid)
      shift
      requested_pid="${1:-}"
      ;;
    *)
      printf 'Usage: %s [--save|--watch] [--pid KITTY_PID]\n' "$0" >&2
      exit 2
      ;;
  esac
  shift
done

process_tree() {
  local root="$1" index=0 current children_file child
  local -a queue=("$root") children=()

  while ((index < ${#queue[@]})); do
    current="${queue[index]}"
    ((index += 1))
    [[ -d "/proc/$current" ]] || continue
    printf '%s\n' "$current"

    children_file="/proc/$current/task/$current/children"
    children=()
    [[ -r "$children_file" ]] && read -r -a children < "$children_file"
    for child in "${children[@]}"; do
      queue+=("$child")
    done
  done
}

find_claude_session() {
  local root="$1" process state session_id session_name
  while read -r process; do
    state="$HOME/.claude/sessions/$process.json"
    [[ -r "$state" ]] || continue
    session_id="$(jq -r '.sessionId // empty' "$state" 2>/dev/null)"
    [[ -n "$session_id" ]] || continue
    session_name="$(jq -r '.name // empty' "$state" 2>/dev/null)"
    printf '%s\t%s\n' "$session_id" "$session_name"
    return 0
  done < <(process_tree "$root")
  return 1
}

find_codex_session() {
  local root="$1" process fd target filename
  local uuid_re='([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$'

  while read -r process; do
    for fd in "/proc/$process/fd/"*; do
      [[ -e "$fd" || -L "$fd" ]] || continue
      target="$(readlink "$fd" 2>/dev/null)" || continue
      target="${target% (deleted)}"
      case "$target" in
        "$HOME"/.codex/sessions/*.jsonl)
          filename="${target##*/}"
          filename="${filename%.jsonl}"
          if [[ "$filename" =~ $uuid_re ]]; then
            printf '%s\n' "${BASH_REMATCH[1]}"
            return 0
          fi
          ;;
      esac
    done
  done < <(process_tree "$root")
  return 1
}

launch_arg() {
  # Kitty parses launch lines with shell-style quoting.
  local value="$1"
  value="${value//\'/\'\"\'\"\'}"
  printf "'%s'" "$value"
}

clean_line() {
  local value="$1"
  value="${value//$'\n'/ }"
  value="${value//$'\r'/ }"
  printf '%s' "$value"
}

session_value() {
  local value
  value="$(clean_line "$1")"
  # Kitty expands variables in session directives; $$ preserves a literal $.
  value="${value//\$/\$\$}"
  printf '%s' "$value"
}

strip_agent_state() {
  local value="$1" previous=""
  while [[ "$value" != "$previous" ]]; do
    previous="$value"
    value="${value#▶ Working · }"
    value="${value#\? Needs input · }"
    value="${value#○ Ready · }"
    value="${value#▶ }"
    value="${value#\? }"
    value="${value#✓ }"
    value="${value#◆ }"
    value="${value#⁇ }"
    value="${value#◇ }"
  done
  printf '%s' "$value"
}

find_tab_title() {
  local kitty_state="$1" window_id="$2"

  [[ -n "$kitty_state" ]] || return 1
  jq -r --argjson window_id "$window_id" '
    first(
      .[]?.tabs[]?
      | select(any(.windows[]?; .id == $window_id))
      | .title
    ) // empty
  ' <<< "$kitty_state" 2>/dev/null
}

resolve_kitty_pid() {
  if [[ -n "$requested_pid" && -d "/proc/$requested_pid" ]]; then
    printf '%s\n' "$requested_pid"
    return 0
  fi
  pgrep -xo kitty 2>/dev/null
}

resolve_claude_executable() {
  local candidate
  for candidate in "$HOME/.local/bin/claude" /usr/local/bin/claude /usr/bin/claude; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  command -v claude 2>/dev/null
}

save_session_unlocked() {
  local kitty_pid children_file child env_file window_id cwd
  local record ordered_window_id tab_count=0 agent_count=0
  local claude_data claude_id claude_name claude_executable codex_id title saved_title command
  local kitty_socket kitty_state
  local previous_agent_count=0
  local session_dir temporary
  local -a window_records=() unordered_window_records=() ordered_window_ids=()
  local -A child_by_window=() included_window=()

  kitty_pid="$(resolve_kitty_pid)" || return 1
  kitty_socket="unix:$runtime_dir/ado-kitty-$kitty_pid"
  kitty_state="$(kitten @ --to "$kitty_socket" ls 2>/dev/null)" || kitty_state=""
  children_file="/proc/$kitty_pid/task/$kitty_pid/children"
  [[ -r "$children_file" ]] || return 1

  local -a direct_children=()
  read -r -a direct_children < "$children_file"
  for child in "${direct_children[@]}"; do
    env_file="/proc/$child/environ"
    [[ -r "$env_file" ]] || continue
    window_id="$(tr '\0' '\n' < "$env_file" 2>/dev/null | sed -n 's/^KITTY_WINDOW_ID=//p' | head -n 1)"
    [[ "$window_id" =~ ^[0-9]+$ ]] || continue
    child_by_window["$window_id"]="$child"
    unordered_window_records+=("$window_id"$'\t'"$child")
  done

  ((${#unordered_window_records[@]} > 0)) || return 1

  # Kitty's tabs array is already in the visible left-to-right order. Window
  # IDs only describe creation order, so sorting numerically here would undo
  # any tab reordering performed by the user.
  if [[ -n "$kitty_state" ]]; then
    mapfile -t ordered_window_ids < <(
      jq -r '.[]?.tabs[]?.windows[]?.id // empty' <<< "$kitty_state" 2>/dev/null
    )
  fi
  for ordered_window_id in "${ordered_window_ids[@]}"; do
    [[ -n "${child_by_window[$ordered_window_id]:-}" ]] || continue
    window_records+=("$ordered_window_id"$'\t'"${child_by_window[$ordered_window_id]}")
    included_window["$ordered_window_id"]=1
  done

  # Retain any process that was absent from a transient remote-control
  # snapshot, placing it after the tabs whose live order was available.
  for record in "${unordered_window_records[@]}"; do
    window_id="${record%%$'\t'*}"
    [[ -n "${included_window[$window_id]:-}" ]] && continue
    window_records+=("$record")
  done
  claude_executable="$(resolve_claude_executable)" || claude_executable="claude"

  session_dir="${session_file%/*}"
  mkdir -p "$session_dir" || return 1
  temporary="$(mktemp "$session_dir/.ado-session.conf.XXXXXX")" || return 1
  chmod 600 "$temporary"

  {
    printf '# Generated by SaveKittySession.sh. Manual edits will be replaced.\n'
    printf '# Closing Kitty stops every process; these commands resume saved agent threads.\n\n'

    for record in "${window_records[@]}"; do
      window_id="${record%%$'\t'*}"
      child="${record#*$'\t'}"
      [[ -d "/proc/$child" ]] || continue
      cwd="$(readlink "/proc/$child/cwd" 2>/dev/null)" || cwd="$HOME"
      cwd="$(clean_line "$cwd")"
      title="Shell · ${cwd##*/}"
      command="zsh"

      claude_data="$(find_claude_session "$child" 2>/dev/null)" || claude_data=""
      if [[ -n "$claude_data" ]]; then
        claude_id="${claude_data%%$'\t'*}"
        claude_name="${claude_data#*$'\t'}"
        [[ "$claude_name" == "$claude_data" ]] && claude_name=""
        title="${claude_name:-Claude · ${cwd##*/}}"
        printf -v command '%q --resume %q; exec zsh -l' "$claude_executable" "$claude_id"
        ((agent_count += 1))
      else
        codex_id="$(find_codex_session "$child" 2>/dev/null)" || codex_id=""
        if [[ -n "$codex_id" ]]; then
          title="Codex · ${cwd##*/}"
          command="codex resume $codex_id; exec zsh -l"
          ((agent_count += 1))
        fi
      fi

      saved_title="$(find_tab_title "$kitty_state" "$window_id")" || saved_title=""
      [[ -n "$saved_title" ]] && title="$saved_title"
      title="$(strip_agent_state "$title")"
      title="$(session_value "$title")"
      ((tab_count > 0)) && printf '\n'
      printf 'new_tab %s\n' "$title"
      printf 'layout tall\n'
      printf 'cd %s\n' "$cwd"
      if [[ "$command" == "zsh" ]]; then
        printf 'launch zsh\n'
      else
        printf 'launch zsh -lc '
        launch_arg "$command"
        printf '\n'
      fi
      ((tab_count += 1))
    done
  } > "$temporary"

  if ((tab_count == 0)); then
    rm -f "$temporary"
    return 1
  fi

  # A missing executable or a transient agent crash leaves a shell behind. Do
  # not let the watcher silently replace known resumable threads with shells.
  if [[ -r "$session_file" ]]; then
    previous_agent_count="$(grep -Ec 'claude .*--resume|codex resume' "$session_file" 2>/dev/null)" || previous_agent_count=0
  fi
  if ((agent_count < previous_agent_count)); then
    rm -f "$temporary"
    printf 'Kept the previous Kitty session: it contains %d resumable agent threads; only %d are currently detectable.\n' \
      "$previous_agent_count" "$agent_count"
    return 0
  fi

  mv -f "$temporary" "$session_file"
  printf 'Saved %d Kitty tabs (%d resumable agent threads) to %s\n' \
    "$tab_count" "$agent_count" "$session_file"
}

save_session() {
  (
    flock -w 5 8 || exit 1
    save_session_unlocked
  ) 8>"$save_lock"
}

if [[ "$mode" == "watch" ]]; then
  exec 9>"$watch_lock"
  flock -n 9 || exit 0
  while true; do
    sleep "$watch_interval_seconds"
    save_session >/dev/null 2>&1 || true
  done
else
  save_session
fi
