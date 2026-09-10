#!/usr/bin/env bash

# Shared by KittyAgentTabState.sh (the lifecycle-hook path, which gets the
# message handed to it) and KittyAgentTabSync.sh (the poller, which has to read
# it back out of the session transcript). Both must answer the same question
# the same way, or a tab's marker changes meaning depending on which one got
# there first.

# True when an assistant message ends by asking the user something.
#
# Only a CLOSING question counts. Scanning the whole trailing paragraph for "?"
# flagged tabs for any incidental question mark ("did that work? Anyway, all
# done.", a "?" glob quoted in prose), so this tests the last non-empty line.
agent_question_at_end() {
  local message="$1" last_line
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

# Last assistant text block in a Claude Code session transcript (JSONL).
# Only the tail is read: these files reach tens of megabytes.
agent_last_assistant_text() {
  local transcript="$1"
  [[ -r "$transcript" ]] || return 1
  tail -n 400 "$transcript" 2>/dev/null | jq -rR '
    fromjson? // empty
    | select(.type == "assistant")
    | .message.content[]?
    | select(.type == "text")
    | .text
  ' 2>/dev/null | awk 'NF { last = $0 } END { print last }'
}
