#!/bin/bash
set -euo pipefail
export TZ="America/New_York"
export TODOIST_API_TOKEN="81d341953323302cf0919e4ec8a8d9531ea6f881"
source /home/nik/.openclaw/workspace/brief-lib.sh

TODO_JSON=$(/home/nik/.npm-global/bin/todoist today --json 2>/dev/null || echo '[]')
TODO_COUNT=$(echo "$TODO_JSON" | jq 'length')
TOP_TASK=$(echo "$TODO_JSON" | jq -r 'sort_by(.due.date // "9999-12-31") | .[0].content // empty')
TODO_LIST=$(echo "$TODO_JSON" | jq -r '.[] | "<li><strong>" + (.content|tostring) + "</strong>" + (if .due.date then " <span class=""muted"">— due " + .due.date + "</span>" else "" end) + "</li>"' 2>/dev/null || true)

if [ "$TODO_COUNT" -gt 0 ]; then
  PRIORITY_MUST="$TOP_TASK"
  PRIORITY_SHOULD=$(echo "$TODO_JSON" | jq -r '.[1].content // empty')
  PRIORITY_IF=$(echo "$TODO_JSON" | jq -r '.[2].content // empty')
else
  PRIORITY_MUST="Keep the day clear for what is actually scheduled."
  PRIORITY_SHOULD=""
  PRIORITY_IF=""
fi

PREV_TASK_COUNT=$(jq -r '.tasks // 0' "$(brief_state_file)" 2>/dev/null || echo 0)
TASK_DELTA=$((TODO_COUNT - PREV_TASK_COUNT))

if [ "$(brief_mode)" = "delta" ]; then
  cat <<HTML
<section class="card">
  <h2>Task Delta</h2>
  <p><strong>${TODO_COUNT}</strong> due or overdue tasks now.</p>
  <p class="muted">Change since last brief: ${TASK_DELTA}.</p>
  <ul>$TODO_LIST</ul>
</section>
HTML
else
  cat <<HTML
<section class="card">
  <h2>Top Priorities</h2>
  <ul>
    <li><strong>Must-do:</strong> ${PRIORITY_MUST}</li>
HTML
  if [ -n "$PRIORITY_SHOULD" ]; then
    cat <<HTML
    <li><strong>Should-do:</strong> ${PRIORITY_SHOULD}</li>
HTML
  fi
  if [ -n "$PRIORITY_IF" ]; then
    cat <<HTML
    <li><strong>If there’s time:</strong> ${PRIORITY_IF}</li>
HTML
  fi
  cat <<HTML
  </ul>
</section>
HTML

  if [ "$TODO_COUNT" -gt 0 ]; then
    cat <<HTML
<section class="card">
  <h2>Task Pressure</h2>
  <p class="muted">$TODO_COUNT due or overdue tasks.</p>
  <ul>$TODO_LIST</ul>
</section>
HTML
  fi
fi

brief_meta SUMMARY "Top priority: ${PRIORITY_MUST}"
brief_meta TODO_COUNT "${TODO_COUNT}"
