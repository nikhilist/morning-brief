#!/bin/bash
set -euo pipefail

LOG_FILE="/home/nik/.openclaw/workspace/.brief-generate.log"
exec 1> >(tee -a "$LOG_FILE") 2>&1

TZ="America/New_York"
export TZ
export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$HOME/.npm-global/bin"
export HOME="/home/nik"
export GOG_KEYRING_BACKEND=file
export GOG_KEYRING_PASSWORD=""
export GOG_ACCOUNT=nikhilist@gmail.com
export HABITICA_USER_ID="404a4487-6eea-4ed3-b60b-03f82092b29a"
export HABITICA_API_TOKEN="e3470ee9-56d7-49f4-bd56-4f3f175bd804"
export TODOIST_API_TOKEN="81d341953323302cf0919e4ec8a8d9531ea6f881"

echo "=== Starting brief generation: $(date) ==="

WORKSPACE="/home/nik/.openclaw/workspace"
OUTPUT_FILE="$WORKSPACE/brief.html"
INDEX_FILE="$WORKSPACE/index.html"
STATE_FILE="$WORKSPACE/.brief-state.json"
DATE=$(date '+%A, %B %-d, %Y')
TIME=$(date '+%I:%M %p %Z')
HOUR=$(date '+%H')
PREV_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo '{}')

if [ "$HOUR" -lt 12 ]; then
  BRIEF_TYPE="Morning"
  BRIEF_MODE="full"
elif [ "$HOUR" -lt 20 ]; then
  BRIEF_TYPE="Afternoon"
  BRIEF_MODE="delta"
else
  BRIEF_TYPE="Evening"
  BRIEF_MODE="delta"
fi
export BRIEF_MODE

run_module() {
  local script="$1"
  if [ -x "$script" ]; then
    "$script"
  else
    echo "<section class=\"card\"><h2>Error</h2><p class=\"muted\">Missing module: $(basename "$script")</p></section>"
  fi
}

extract_html() {
  sed '/^__.*__.*$/d'
}

extract_meta() {
  local key="$1"
  sed -n "s/^__${key}__//p" | head -n1
}

WEATHER_RAW=$(run_module "$WORKSPACE/brief-weather.sh")
CALENDAR_RAW=$(run_module "$WORKSPACE/brief-calendar.sh")
EMAIL_RAW=$(run_module "$WORKSPACE/brief-email.sh")
TASKS_RAW=$(run_module "$WORKSPACE/brief-tasks.sh")
HABITS_RAW=$(run_module "$WORKSPACE/brief-habits.sh")
ARSENAL_RAW=$(run_module "$WORKSPACE/arsenal-brief.sh")
MARKET_INTEL_RAW=$(run_module "$WORKSPACE/brief-market-intel.sh")
UPCOMING_PREP_RAW=$(run_module "$WORKSPACE/brief-upcoming-prep.sh")

WEATHER_HTML=$(printf '%s\n' "$WEATHER_RAW" | extract_html)
CALENDAR_HTML=$(printf '%s\n' "$CALENDAR_RAW" | extract_html)
EMAIL_HTML=$(printf '%s\n' "$EMAIL_RAW" | extract_html)
TASKS_HTML=$(printf '%s\n' "$TASKS_RAW" | extract_html)
HABITS_HTML=$(printf '%s\n' "$HABITS_RAW" | extract_html)
ARSENAL_HTML=$(printf '%s\n' "$ARSENAL_RAW" | extract_html)
MARKET_INTEL_HTML=$(printf '%s\n' "$MARKET_INTEL_RAW" | extract_html)
UPCOMING_PREP_HTML=$(printf '%s\n' "$UPCOMING_PREP_RAW" | extract_html)

DAY_SHAPE=$(printf '%s\n' "$CALENDAR_RAW" | extract_meta SUMMARY)
TOMORROW_SHAPE=$(printf '%s\n' "$CALENDAR_RAW" | extract_meta TOMORROW)
EMAIL_SUMMARY=$(printf '%s\n' "$EMAIL_RAW" | extract_meta SUMMARY)
TASK_SUMMARY=$(printf '%s\n' "$TASKS_RAW" | extract_meta SUMMARY)
WEATHER_SUMMARY=$(printf '%s\n' "$WEATHER_RAW" | extract_meta SUMMARY)
HABIT_SUMMARY=$(printf '%s\n' "$HABITS_RAW" | extract_meta SUMMARY)
MARKET_INTEL_SUMMARY=$(printf '%s\n' "$MARKET_INTEL_RAW" | extract_meta SUMMARY)
UPCOMING_PREP_SUMMARY=$(printf '%s\n' "$UPCOMING_PREP_RAW" | extract_meta SUMMARY)
CURRENT_EMAIL_IDS=$(printf '%s\n' "$EMAIL_RAW" | extract_meta EMAIL_IDS)
TODO_COUNT=$(printf '%s\n' "$TASKS_RAW" | extract_meta TODO_COUNT)
HABIT_COUNT=$(printf '%s\n' "$HABITS_RAW" | extract_meta HABIT_COUNT)

if [ "$BRIEF_TYPE" != "Evening" ]; then
  MARKET_INTEL_HTML=""
fi

INSIGHT_JSON=$(python3 "$WORKSPACE/brief-insight.py" <<JSON
{
  "brief_type": $(printf '%s' "$BRIEF_TYPE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "date": $(printf '%s' "$DATE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "day_shape": $(printf '%s' "$DAY_SHAPE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "tomorrow_shape": $(printf '%s' "$TOMORROW_SHAPE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "decision_text": $(printf '%s' "$TASK_SUMMARY" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "email_summary": $(printf '%s' "$EMAIL_SUMMARY" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "weather_summary": $(printf '%s' "$WEATHER_SUMMARY" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "habit_summary": $(printf '%s' "$HABIT_SUMMARY" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "upcoming_summary": $(printf '%s' "$UPCOMING_PREP_SUMMARY" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "market_summary": $(printf '%s' "$MARKET_INTEL_SUMMARY" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "todo_count": ${TODO_COUNT:-0},
  "habit_count": ${HABIT_COUNT:-0},
  "calendar_html": $(printf '%s' "$CALENDAR_HTML" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "tasks_html": $(printf '%s' "$TASKS_HTML" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "email_html": $(printf '%s' "$EMAIL_HTML" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "weather_html": $(printf '%s' "$WEATHER_HTML" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "habits_html": $(printf '%s' "$HABITS_HTML" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "arsenal_html": $(printf '%s' "$ARSENAL_HTML" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "upcoming_html": $(printf '%s' "$UPCOMING_PREP_HTML" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
}
JSON
)
PATTERN_TEXT=$(printf '%s' "$INSIGHT_JSON" | jq -r '.pattern // "Today needs prioritization that respects real-world timing, not just task count."' 2>/dev/null)
TOMORROW_PREP_TEXT=$(printf '%s' "$INSIGHT_JSON" | jq -r '.tomorrow_prep // empty' 2>/dev/null)
RECOMMENDED_NEXT_MOVE=$(printf '%s' "$INSIGHT_JSON" | jq -r '.next_move // "Handle the highest-friction real-world task first, before the inbox or background noise expands to fill the day."' 2>/dev/null)
if [ -z "$TOMORROW_PREP_TEXT" ] || [ "$TOMORROW_PREP_TEXT" = "null" ]; then
  TOMORROW_PREP_TEXT="$TOMORROW_SHAPE"
fi

DECISION_TEXT="$TASK_SUMMARY"
if [ -n "${MARKET_INTEL_SUMMARY:-}" ] && [ "$BRIEF_TYPE" != "Morning" ]; then
  DECISION_TEXT="$MARKET_INTEL_SUMMARY"
fi
if [ "$BRIEF_TYPE" = "Morning" ] && [ "${TODO_COUNT:-0}" -gt 0 ]; then
  DECISION_TEXT="$TASK_SUMMARY"
fi

cat > "$INDEX_FILE" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Nik's $BRIEF_TYPE Brief</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 24px;
      background: #0d1117;
      color: #e6edf3;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      line-height: 1.55;
    }
    .container { max-width: 900px; margin: 0 auto; }
    header { margin-bottom: 24px; }
    h1 { margin: 0 0 6px; font-size: 34px; }
    .sub { color: #8b949e; }
    .card {
      background: #161b22;
      border: 1px solid #30363d;
      border-radius: 16px;
      padding: 18px 20px;
      margin-bottom: 16px;
    }
    h2 { margin: 0 0 12px; color: #58a6ff; font-size: 18px; }
    h3 { margin: 16px 0 10px; color: #c9d1d9; font-size: 15px; }
    ul { margin: 0; padding-left: 20px; }
    li { margin: 8px 0; }
    .muted { color: #8b949e; }
    .event { display: flex; gap: 12px; padding: 8px 0; border-bottom: 1px solid rgba(255,255,255,0.05); }
    .event:last-child { border-bottom: none; }
    .event-time { min-width: 72px; color: #58a6ff; }
    .calendar-tag { color: #8b949e; font-size: 12px; }
    .footer { color: #8b949e; text-align: center; padding: 24px 0 12px; }
    .arsenal { border-left: 4px solid #ef0107; }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>$BRIEF_TYPE Brief</h1>
      <div class="sub">$DATE · Princeton, NJ · Updated $TIME</div>
    </header>

    <section class="card">
      <h2>Executive Summary</h2>
      <ul>
        <li><strong>Shape of the day:</strong> ${DAY_SHAPE}</li>
        <li><strong>Main decision:</strong> ${DECISION_TEXT}</li>
        <li><strong>Attention risk:</strong> ${EMAIL_SUMMARY}</li>
        <li><strong>Environmental drag:</strong> ${WEATHER_SUMMARY}</li>
        <li><strong>Coming up soon:</strong> ${UPCOMING_PREP_SUMMARY}</li>
      </ul>
    </section>

    <section class="card">
      <h2>Pattern to Notice</h2>
      <p>$PATTERN_TEXT</p>
    </section>

    ${UPCOMING_PREP_HTML}
    ${MARKET_INTEL_HTML}
    ${TASKS_HTML}
    ${EMAIL_HTML}
    ${WEATHER_HTML}
    ${HABITS_HTML}
    ${ARSENAL_HTML}

    <section class="card">
      <h2>Tomorrow Prep</h2>
      <p>$TOMORROW_PREP_TEXT</p>
    </section>

    <section class="card">
      <h2>Recommended Next Move</h2>
      <p>$RECOMMENDED_NEXT_MOVE</p>
    </section>

    <div class="footer">
      <div>Last updated: $TIME</div>
      <div><a href="https://github.com/nikhilist/morning-brief" style="color:#58a6ff;">github.com/nikhilist/morning-brief</a></div>
    </div>
  </div>
</body>
</html>
HTML

cp "$INDEX_FILE" "$OUTPUT_FILE"
echo "{\"emails\":${CURRENT_EMAIL_IDS:-[]},\"tasks\":${TODO_COUNT:-0},\"timestamp\":\"$(date -Iseconds)\"}" > "$STATE_FILE"

cd "$WORKSPACE"
git add index.html brief.html .brief-state.json generate-brief-html.sh arsenal-brief.sh brief-*.sh
git commit -m "Rewrite $BRIEF_TYPE brief structure: $DATE $TIME" 2>/dev/null || true
git push origin main 2>&1 || echo "Push failed"

echo "$BRIEF_TYPE brief generated"
echo "GitHub Pages: https://nikhilist.github.io/morning-brief/"
echo "=== Finished: $(date) ==="
