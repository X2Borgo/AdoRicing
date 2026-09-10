#!/usr/bin/env bash

# Reconcile Kitty tab markers with what the agent is actually doing.
#
# KittyAgentTabState.sh drives the markers from Claude/Codex lifecycle hooks,
# which is fast but not complete: some turn endings emit no Stop at all (an
# interrupt, a crashed session, a straggling tool event) and idle_prompt does
# not always arrive either, so a tab can stay pinned on the working marker with
# nothing left to clear it -- or sit on "ready" while the agent is busy again.
#
# Claude Code publishes its own state in the WINDOW title: "✳ " while it waits
# on the user, and a spinner (◐ ◑ ◒ ◓) while it works. That is ground truth
# and needs no hook, so this poller compares it against the tab marker and
# corrects the disagreements.
#
# Deliberately narrow:
#   * only tabs that already carry a Claude marker are touched, so untitled
#     tabs, the transient "new" label and Codex tabs are left alone;
#   * "needs input" on an idle session is a real state, not a stuck marker;
#   * a tab must look idle twice in a row before the working marker is
#     dropped, because the window title lags a prompt submission by a moment.

set -uo pipefail

readonly POLL=4          # seconds between reconciliation passes
readonly IDLE_CONFIRM=2  # consecutive idle samples before clearing "working"

readonly WORKING="◆ "
readonly INPUT="⁇ "
readonly READY="◇ "

log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" >&2; }

sockets() {
  local s found=1
  for s in "${XDG_RUNTIME_DIR:-/tmp}"/ado-kitty-*; do
    [[ -S "$s" ]] || continue
    printf 'unix:%s\n' "$s"
    found=0
  done
  return "$found"
}

# window_id <TAB> tab_title <TAB> window_title, for tabs carrying a Claude marker
tab_rows() {
  kitten @ --to "$1" ls 2>/dev/null | jq -r '
    .[]?.tabs[]?
    | . as $t
    | ($t.windows[0]? // empty) as $w
    | select($w != null)
    | [ $w.id, $t.title, ($w.title // "") ]
    | @tsv' 2>/dev/null
}

declare -A idle_streak=()

reconcile_socket() {
  local sock="$1" wid tab win marker rest want
  while IFS=$'\t' read -r wid tab win; do
    [[ "$wid" =~ ^[0-9]+$ ]] || continue

    case "$tab" in
      "$WORKING"*) marker="$WORKING"; rest="${tab#"$WORKING"}" ;;
      "$INPUT"*) marker="$INPUT"; rest="${tab#"$INPUT"}" ;;
      "$READY"*) marker="$READY"; rest="${tab#"$READY"}" ;;
      *) continue ;; # no Claude marker: not ours to rewrite
    esac

    case "$win" in
      "✳ "*) # waiting on the user
        idle_streak["$wid"]=$(( ${idle_streak["$wid"]:-0} + 1 ))
        # "needs input" is a legitimate idle state; only rescue "working"
        if [[ "$marker" == "$WORKING" ]] && (( ${idle_streak["$wid"]} >= IDLE_CONFIRM )); then
          want="$READY"
        else
          continue
        fi
        ;;
      "◐ "* | "◑ "* | "◒ "* | "◓ "*) # spinning: the agent is working
        idle_streak["$wid"]=0
        [[ "$marker" == "$WORKING" ]] && continue
        want="$WORKING"
        ;;
      *) # not a Claude Code window (Codex, a plain shell, ...)
        unset 'idle_streak[$wid]'
        continue
        ;;
    esac

    kitten @ --to "$sock" set-tab-title --match "id:$wid" "${want}${rest}" >/dev/null 2>&1 &&
      log "window $wid: ${marker}${rest} -> ${want}${rest}"
    idle_streak["$wid"]=0
  done < <(tab_rows "$sock")
}

run_once() {
  local sock
  while read -r sock; do
    reconcile_socket "$sock"
  done < <(sockets)
}

case "${1:---watch}" in
  --once)
    # The idle confirmation counter lives in this process, so a single pass can
    # never clear a stuck working marker. Sample twice.
    run_once
    sleep 2
    run_once
    ;;
  --watch)
    lock="${XDG_RUNTIME_DIR:-/tmp}/ado-kitty-tab-sync.lock"
    exec 9>"$lock"
    flock -n 9 || { log "already running"; exit 0; }
    while true; do
      run_once
      sleep "$POLL"
    done
    ;;
  *)
    echo "usage: ${0##*/} [--once|--watch]" >&2
    exit 2
    ;;
esac
