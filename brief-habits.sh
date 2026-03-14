#!/bin/bash
set -euo pipefail
export TZ="America/New_York"

HABITICA_OUT=$(~/.openclaw/workspace/skills/habitica-skill/scripts/habitica.sh list dailys 2>/dev/null || true)
HABIT_PENDING_NAMES=$(echo "$HABITICA_OUT" | awk 'BEGIN{pending=0} /^\[daily\]/{getline; if ($0 ~ /^  /) print substr($0,3)}')
HABIT_PENDING_COUNT=$(printf '%s\n' "$HABIT_PENDING_NAMES" | sed '/^$/d' | wc -l | tr -d ' ')
HABIT_LIST_HTML=""
if [ -n "$HABIT_PENDING_NAMES" ]; then
  while IFS= read -r habit; do
    [ -n "$habit" ] && HABIT_LIST_HTML+="<li>$habit</li>"
  done <<< "$HABIT_PENDING_NAMES"
fi

if [ "$HABIT_PENDING_COUNT" -ge 3 ] 2>/dev/null; then
  HABIT_PATTERN="Basics are still open late, which usually means the trigger is weak, not the intention."
else
  HABIT_PATTERN="Personal maintenance looks under control."
fi

cat <<HTML
<section class="card">
  <h2>Habits / Maintenance</h2>
  <p>$HABIT_PATTERN</p>
HTML
if [ -n "$HABIT_LIST_HTML" ]; then
cat <<HTML
  <ul>$HABIT_LIST_HTML</ul>
HTML
fi
cat <<HTML
</section>
__SUMMARY__${HABIT_PATTERN}
__HABIT_COUNT__${HABIT_PENDING_COUNT}
HTML
