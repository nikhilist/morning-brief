#!/bin/bash
set -euo pipefail
export TZ="America/New_York"
export TODOIST_API_TOKEN="81d341953323302cf0919e4ec8a8d9531ea6f881"
source /home/nik/.openclaw/workspace/brief-lib.sh

INBOX_PROJECT_ID="6CrgCMq6FmVMQQM8"
TODAY_JSON=$(/home/nik/.npm-global/bin/todoist today --json 2>/dev/null || echo '[]')
INBOX_JSON=$(/home/nik/.npm-global/bin/todoist tasks -p "Inbox" --json 2>/dev/null || echo '[]')

COMBINED_JSON=$(jq -n --argjson today "$TODAY_JSON" --argjson inbox "$INBOX_JSON" '
  ($today + $inbox)
  | unique_by(.id)
')

TODO_COUNT=$(echo "$TODAY_JSON" | jq 'length')
INBOX_COUNT=$(echo "$INBOX_JSON" | jq 'length')
INBOX_UNSCHEDULED_COUNT=$(echo "$INBOX_JSON" | jq '[.[] | select((.due.date // "") == "")] | length')
LATEST_INBOX_TASK_AT=$(echo "$INBOX_JSON" | jq -r 'sort_by(.updatedAt // .addedAt // "") | last.updatedAt // last.addedAt // empty')

TOP_TASK=$(echo "$COMBINED_JSON" | jq -r '
  sort_by(
    if (.due.date // "") == "" then "9999-12-31" else .due.date end,
    .childOrder // 999999
  ) | .[0].content // empty')

PRIORITY_MUST="$TOP_TASK"
PRIORITY_SHOULD=$(echo "$COMBINED_JSON" | jq -r '
  sort_by(
    if (.due.date // "") == "" then "9999-12-31" else .due.date end,
    .childOrder // 999999
  ) | .[1].content // empty')
PRIORITY_IF=$(echo "$COMBINED_JSON" | jq -r '
  sort_by(
    if (.due.date // "") == "" then "9999-12-31" else .due.date end,
    .childOrder // 999999
  ) | .[2].content // empty')

if [ -z "$PRIORITY_MUST" ]; then
  PRIORITY_MUST="Keep the day clear for what is actually scheduled."
  PRIORITY_SHOULD=""
  PRIORITY_IF=""
fi

DUE_LIST=$(echo "$TODAY_JSON" | jq -r '
  sort_by(.due.date // "9999-12-31", .childOrder // 999999)[] |
  "<li><strong>" + (.content|tostring) + "</strong>" +
  (if .due.date then " <span class=\"muted\">— due " + .due.date + "</span>" else "" end) +
  "</li>"' 2>/dev/null || true)

INBOX_UNSCHEDULED_LIST=$(echo "$INBOX_JSON" | jq -r '
  map(select((.due.date // "") == ""))
  | sort_by(.childOrder // 999999)[] |
  "<li><strong>" + (.content|tostring) + "</strong><span class=\"muted\"> — Inbox / no due date</span></li>"' 2>/dev/null || true)

PREV_TASK_COUNT=$(jq -r '.tasks // 0' "$(brief_state_file)" 2>/dev/null || echo 0)
TASK_DELTA=$((TODO_COUNT - PREV_TASK_COUNT))

if [ "$(brief_mode)" = "delta" ]; then
  if [ "$TASK_DELTA" -ne 0 ] || [ "$INBOX_UNSCHEDULED_COUNT" -gt 0 ]; then
    cat <<HTML
<section class="card">
  <h2>Tasks</h2>
  <p><strong>${TODO_COUNT}</strong> due or overdue tasks now.</p>
  <p class="muted">Change since last brief: ${TASK_DELTA}.</p>
HTML
    if [ -n "$DUE_LIST" ]; then
      cat <<HTML
  <ul>$DUE_LIST</ul>
HTML
    fi
    if [ "$INBOX_UNSCHEDULED_COUNT" -gt 0 ]; then
      cat <<HTML
  <h3>Inbox / Unscheduled</h3>
  <p class="muted">${INBOX_UNSCHEDULED_COUNT} Inbox task(s) without due dates.</p>
  <ul>$INBOX_UNSCHEDULED_LIST</ul>
HTML
    fi
    cat <<HTML
</section>
HTML
  fi
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

  if [ "$TODO_COUNT" -gt 0 ] || [ "$INBOX_UNSCHEDULED_COUNT" -gt 0 ]; then
    cat <<HTML
<section class="card">
  <h2>Task Pressure</h2>
  <p class="muted">$TODO_COUNT due or overdue task(s). $INBOX_UNSCHEDULED_COUNT unscheduled Inbox task(s).</p>
HTML
    if [ "$TODO_COUNT" -gt 0 ] && [ -n "$DUE_LIST" ]; then
      cat <<HTML
  <h3>Due / Overdue</h3>
  <ul>$DUE_LIST</ul>
HTML
    fi
    if [ "$INBOX_UNSCHEDULED_COUNT" -gt 0 ]; then
      cat <<HTML
  <h3>Inbox / No Due Date</h3>
  <ul>$INBOX_UNSCHEDULED_LIST</ul>
HTML
    fi
    cat <<HTML
</section>
HTML
  fi
fi

TASK_HEADLINES=$(echo "$COMBINED_JSON" | jq -r '
  sort_by(
    if (.due.date // "") == "" then "9999-12-31" else .due.date end,
    .childOrder // 999999
  ) | .[0:5] | map(.content) | join(" | ")' 2>/dev/null)

brief_meta SUMMARY "Top priority: ${PRIORITY_MUST}"
brief_meta TODO_COUNT "${TODO_COUNT}"
brief_meta TASK_TOP "${TASK_HEADLINES}"
brief_meta INBOX_UNSCHEDULED_COUNT "${INBOX_UNSCHEDULED_COUNT}"
brief_meta LATEST_INBOX_TASK_AT "${LATEST_INBOX_TASK_AT}"
