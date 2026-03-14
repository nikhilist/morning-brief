#!/bin/bash
# Shared helpers for brief modules
set -euo pipefail

brief_escape_html() {
  python3 -c 'import html,sys; print(html.escape(sys.stdin.read()), end="")'
}

brief_meta() {
  local key="$1"
  shift
  printf '__%s__%s\n' "$key" "$*"
}

brief_mode() {
  printf '%s' "${BRIEF_MODE:-full}"
}

brief_state_file() {
  printf '%s' "/home/nik/.openclaw/workspace/.brief-state.json"
}

brief_tmp_dir() {
  mktemp -d
}

brief_json_get() {
  local file="$1"
  local jq_expr="$2"
  jq -r "$jq_expr" "$file" 2>/dev/null
}

brief_prev_state_to_file() {
  local jq_expr="$1"
  local out_file="$2"
  local state
  state=$(brief_state_file)
  if [ -f "$state" ]; then
    jq -r "$jq_expr" "$state" 2>/dev/null > "$out_file" || :
  else
    : > "$out_file"
  fi
}
