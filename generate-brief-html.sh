#!/bin/bash
set -euo pipefail

LOG_FILE="/home/nik/.openclaw/workspace/.brief-generate.log"
exec 1> >(tee -a "$LOG_FILE") 2>&1

TZ="America/New_York"
export TZ

echo "=== Starting brief generation: $(date) ==="

OUTPUT_FILE="/home/nik/.openclaw/workspace/brief.html"
INDEX_FILE="/home/nik/.openclaw/workspace/index.html"
STATE_FILE="/home/nik/.openclaw/workspace/.brief-state.json"
RSS_FILE="/home/nik/.openclaw/workspace/.arseblog-feed.xml"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

DATE=$(date '+%A, %B %-d, %Y')
TIME=$(date '+%I:%M %p %Z')
HOUR=$(date '+%H')
TODAY_START=$(date '+%Y-%m-%d')
TODAY_END=$(date -d '+1 day' '+%Y-%m-%d' 2>/dev/null || date -v+1d '+%Y-%m-%d')
TOMORROW_START=$(date -d '+1 day' '+%Y-%m-%d' 2>/dev/null || date -v+1d '+%Y-%m-%d')
TOMORROW_END=$(date -d '+2 day' '+%Y-%m-%d' 2>/dev/null || date -v+2d '+%Y-%m-%d')

if [ "$HOUR" -lt 12 ]; then
  BRIEF_TYPE="Morning"
elif [ "$HOUR" -lt 20 ]; then
  BRIEF_TYPE="Afternoon"
else
  BRIEF_TYPE="Evening"
fi

export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$HOME/.npm-global/bin"
export HOME="/home/nik"
export GOG_KEYRING_BACKEND=file
export GOG_KEYRING_PASSWORD=""
export GOG_ACCOUNT=nikhilist@gmail.com
export HABITICA_USER_ID="404a4487-6eea-4ed3-b60b-03f82092b29a"
export HABITICA_API_TOKEN="e3470ee9-56d7-49f4-bd56-4f3f175bd804"
export TODOIST_API_TOKEN="81d341953323302cf0919e4ec8a8d9531ea6f881"

escape_html() {
  python3 -c 'import html,sys; print(html.escape(sys.stdin.read()), end="")'
}

# Previous state
PREV_EMAILS_FILE="$TMP_DIR/prev_emails.txt"
CURRENT_EMAILS_FILE="$TMP_DIR/current_emails.txt"
NEW_EMAILS_FILE="$TMP_DIR/new_emails.txt"
if [ -f "$STATE_FILE" ]; then
  jq -r '.emails[]? // empty' "$STATE_FILE" 2>/dev/null | sort -u > "$PREV_EMAILS_FILE" || :
else
  : > "$PREV_EMAILS_FILE"
fi

# Weather
WEATHER_JSON=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=40.3573&longitude=-74.6672&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max&forecast_days=3&timezone=America%2FNew_York")
TEMP=$(echo "$WEATHER_JSON" | jq -r '.current.temperature_2m // 0')
FEELS_LIKE=$(echo "$WEATHER_JSON" | jq -r '.current.apparent_temperature // 0')
WIND_KMH=$(echo "$WEATHER_JSON" | jq -r '.current.wind_speed_10m // 0')
TODAY_HIGH_C=$(echo "$WEATHER_JSON" | jq -r '.daily.temperature_2m_max[0] // 0')
TODAY_LOW_C=$(echo "$WEATHER_JSON" | jq -r '.daily.temperature_2m_min[0] // 0')
TOMORROW_HIGH_C=$(echo "$WEATHER_JSON" | jq -r '.daily.temperature_2m_max[1] // 0')
TOMORROW_LOW_C=$(echo "$WEATHER_JSON" | jq -r '.daily.temperature_2m_min[1] // 0')
TOMORROW_PRECIP=$(echo "$WEATHER_JSON" | jq -r '.daily.precipitation_probability_max[1] // 0')
TEMP_F=$(echo "scale=0; ($TEMP * 9/5) + 32" | bc -l 2>/dev/null | cut -d. -f1)
FEELS_F=$(echo "scale=0; ($FEELS_LIKE * 9/5) + 32" | bc -l 2>/dev/null | cut -d. -f1)
TODAY_HIGH_F=$(echo "scale=0; ($TODAY_HIGH_C * 9/5) + 32" | bc -l 2>/dev/null | cut -d. -f1)
TODAY_LOW_F=$(echo "scale=0; ($TODAY_LOW_C * 9/5) + 32" | bc -l 2>/dev/null | cut -d. -f1)
TOMORROW_HIGH_F=$(echo "scale=0; ($TOMORROW_HIGH_C * 9/5) + 32" | bc -l 2>/dev/null | cut -d. -f1)
TOMORROW_LOW_F=$(echo "scale=0; ($TOMORROW_LOW_C * 9/5) + 32" | bc -l 2>/dev/null | cut -d. -f1)
WIND_MPH=$(echo "scale=0; $WIND_KMH * 0.621371" | bc -l 2>/dev/null | cut -d. -f1)

if [ "$WIND_MPH" -ge 18 ] 2>/dev/null; then
  WEATHER_CALL="Windy enough to be annoying."
elif [ "$TOMORROW_PRECIP" -ge 60 ] 2>/dev/null; then
  WEATHER_CALL="Tomorrow has real rain risk."
else
  WEATHER_CALL="Nothing weather-wise should get in your way."
fi

# Email
EMAILS_JSON=$(gog gmail search 'is:unread' --json 2>/dev/null || echo '{"threads":[]}')
echo "$EMAILS_JSON" | jq -r '.threads[]?.id' | sort -u > "$CURRENT_EMAILS_FILE"
comm -23 "$CURRENT_EMAILS_FILE" "$PREV_EMAILS_FILE" > "$NEW_EMAILS_FILE" || :
EMAIL_COUNT=$(echo "$EMAILS_JSON" | jq '.threads | length')
NEW_COUNT=$(wc -l < "$NEW_EMAILS_FILE" 2>/dev/null | tr -d ' ')
NEW_COUNT=${NEW_COUNT:-0}

echo "$EMAILS_JSON" | jq '
  .threads // [] |
  map(. + {
    signal: (
      (if ((.from // "") | test("ClassDojo|Google Voice|Monarch|school|teacher|calendar|doctor|daycare|parent"; "i")) then 100 else 0 end) +
      (if ((.subject // "") | test("event|message|update|reminder|invoice|statement|text"; "i")) then 20 else 0 end) +
      (if ((.from // "") | test("Huckberry|The Athletic|Nothing Technology|Paumanok|E\\*TRADE|ArseMail|promo|noreply"; "i")) then -40 else 0 end)
    )
  }) |
  map(. + {bucket: (if .signal >= 80 then "needs" elif .signal >= 20 then "noting" else "ignore" end)})
' > "$TMP_DIR/scored_emails.json"

NEEDS_JSON=$(jq '[.[] | select(.bucket == "needs")][0:3]' "$TMP_DIR/scored_emails.json")
NOTING_JSON=$(jq '[.[] | select(.bucket == "noting")][0:3]' "$TMP_DIR/scored_emails.json")
IGNORE_COUNT=$(jq '[.[] | select(.bucket == "ignore")] | length' "$TMP_DIR/scored_emails.json")

# Calendars: Nik + Neel + Arsenal
NIK_EVENTS=$(gog calendar events "nikhilist@gmail.com" --from "$TODAY_START" --to "$TODAY_END" --json 2>/dev/null || echo '{"events":[]}')
NEEL_EVENTS=$(gog calendar events "8tdo49s92dr6h34pcros8a17k8@group.calendar.google.com" --from "$TODAY_START" --to "$TODAY_END" --json 2>/dev/null || echo '{"events":[]}')
ARSENAL_EVENTS=$(gog calendar events "08ac8665d76573fd7cfcb0e0cb13ed3a951e59b7b1c4c6eabc9adaae8a74e615@group.calendar.google.com" --from "$TODAY_START" --to "$TODAY_END" --json 2>/dev/null || echo '{"events":[]}')
ALL_EVENTS=$(jq -s '{events: (.[0].events + .[1].events + .[2].events)}' <(echo "$NIK_EVENTS") <(echo "$NEEL_EVENTS") <(echo "$ARSENAL_EVENTS") 2>/dev/null || echo '{"events":[]}')
EVENT_COUNT=$(echo "$ALL_EVENTS" | jq '.events | length')
EVENT_LIST_HTML=$(echo "$ALL_EVENTS" | jq -r '.events | sort_by(.start.dateTime // .start.date // "")[] | "<div class=""event""><div class=""event-time"">" + (.start.date // ((.start.dateTime | split("T")[1])[:5])) + "</div><div class=""event-title""><span class=""calendar-tag"">" + (.organizer.email // "calendar") + "</span> " + (.summary // "Untitled") + "</div></div>"' 2>/dev/null || true)
DAY_SHAPE=$(echo "$ALL_EVENTS" | jq -r '
  .events | sort_by(.start.dateTime // .start.date // "") |
  if length == 0 then "No real calendar constraints today."
  else map(.summary) | join(" • ") end
' 2>/dev/null)

TOMORROW_EVENTS=$(jq -s '{events: (.[0].events + .[1].events + .[2].events)}' \
  <(gog calendar events "nikhilist@gmail.com" --from "$TOMORROW_START" --to "$TOMORROW_END" --json 2>/dev/null || echo '{"events":[]}') \
  <(gog calendar events "8tdo49s92dr6h34pcros8a17k8@group.calendar.google.com" --from "$TOMORROW_START" --to "$TOMORROW_END" --json 2>/dev/null || echo '{"events":[]}') \
  <(gog calendar events "08ac8665d76573fd7cfcb0e0cb13ed3a951e59b7b1c4c6eabc9adaae8a74e615@group.calendar.google.com" --from "$TOMORROW_START" --to "$TOMORROW_END" --json 2>/dev/null || echo '{"events":[]}') 2>/dev/null || echo '{"events":[]}')
TOMORROW_SHAPE=$(echo "$TOMORROW_EVENTS" | jq -r '
  .events | sort_by(.start.dateTime // .start.date // "") |
  if length == 0 then "Tomorrow is open right now."
  else map(.summary) | join(" • ") end
' 2>/dev/null)

# Tasks
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

# Habits
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

# Arsenal from Arseblog RSS
curl -sL "https://arseblog.news/feed/" -o "$RSS_FILE" || true
python3 - "$RSS_FILE" "$TMP_DIR/arsenal.json" <<'PY'
import sys, json, re, html, email.utils, time
from xml.etree import ElementTree as ET
rss_path, out_path = sys.argv[1], sys.argv[2]
items = []
try:
    root = ET.parse(rss_path).getroot()
    channel = root.find('channel')
    now = time.time()
    if channel is not None:
        for item in channel.findall('item')[:8]:
            title = (item.findtext('title') or '').strip()
            pub = (item.findtext('pubDate') or '').strip()
            desc = item.findtext('description') or ''
            desc = re.sub(r'<[^>]+>', ' ', desc)
            desc = html.unescape(re.sub(r'\s+', ' ', desc)).strip()
            ts = 0
            try:
                ts = email.utils.mktime_tz(email.utils.parsedate_tz(pub))
            except Exception:
                pass
            items.append({"title": title, "desc": desc[:280], "ts": ts})
    fresh = [x for x in items if x.get('ts', 0) and x['ts'] >= now - 86400]
    out = fresh[:3] if fresh else items[:3]
except Exception:
    out = []
with open(out_path, 'w') as f:
    json.dump(out, f)
PY
ARSENAL_HTML=$(jq -r '.[] | "<li><strong>" + .title + "</strong><br><span class=""muted"">" + .desc + "</span></li>"' "$TMP_DIR/arsenal.json" 2>/dev/null || true)
ARSENAL_SUMMARY=$(jq -r 'if length == 0 then "No fresh Arseblog posts surfaced." else .[0].title end' "$TMP_DIR/arsenal.json" 2>/dev/null)

# Pattern recognition
PATTERN_TEXT=""
if [ "$TODO_COUNT" -gt 0 ] && [ "$NEW_COUNT" -gt 5 ]; then
  PATTERN_TEXT="Admin backlog and inbox noise are competing for the same attention. That is usually a sign to clear one annoying real-world task before opening the inbox too far."
elif [ "$TODO_COUNT" -gt 0 ]; then
  PATTERN_TEXT="The tasks hanging around look more nuisance-driven than difficult. That usually means they need an early slot, not more thought."
elif [ "$NEW_COUNT" -gt 5 ]; then
  PATTERN_TEXT="The inbox is active, but most of the volume is ambient noise rather than meaningful demand."
else
  PATTERN_TEXT="The day looks structurally calm; the challenge is choosing the right first move."
fi

# Recommended next move
if [ "$BRIEF_TYPE" = "Morning" ]; then
  NEXT_MOVE=${PRIORITY_MUST:-"Use the open morning to clear one real task before the day fragments."}
elif [ "$BRIEF_TYPE" = "Afternoon" ]; then
  NEXT_MOVE="Recalibrate now: finish one concrete task, then stop pretending the inbox is a plan."
else
  NEXT_MOVE="Set up tomorrow by deciding the first real task tonight, so the morning starts clean."
fi

# Executive summary
SUMMARY_HTML=""
add_summary() {
  SUMMARY_HTML+="<li>$(printf '%s' "$1" | escape_html)</li>"
}
add_summary "$DAY_SHAPE"
add_summary "Top priority: ${PRIORITY_MUST:-Keep the day simple.}"
if [ "$NEW_COUNT" -gt 0 ] 2>/dev/null; then add_summary "$NEW_COUNT new unread emails since the last brief; most should be triaged, not read end-to-end."; fi
add_summary "$WEATHER_CALL"
add_summary "Arsenal watch: $ARSENAL_SUMMARY"

# Email HTML sections
render_email_bucket() {
  local json="$1"
  echo "$json" | jq -r '.[] | "<li><strong>" + (.from // "Unknown") + "</strong> — " + (.subject // "(no subject)") + "</li>"' 2>/dev/null || true
}
EMAIL_NEEDS_HTML=$(render_email_bucket "$NEEDS_JSON")
EMAIL_NOTING_HTML=$(render_email_bucket "$NOTING_JSON")

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
    ul { margin: 0; padding-left: 20px; }
    li { margin: 8px 0; }
    .muted { color: #8b949e; }
    .event { display: flex; gap: 12px; padding: 8px 0; border-bottom: 1px solid rgba(255,255,255,0.05); }
    .event:last-child { border-bottom: none; }
    .event-time { min-width: 72px; color: #58a6ff; }
    .calendar-tag { color: #8b949e; font-size: 12px; }
    .split { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
    .arsenal { border-left: 4px solid #ef0107; }
    .footer { color: #8b949e; text-align: center; padding: 24px 0 12px; }
    @media (max-width: 700px) { .split { grid-template-columns: 1fr; } }
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
        $SUMMARY_HTML
      </ul>
    </section>

    <section class="card">
      <h2>Day at a Glance</h2>
      <p>${DAY_SHAPE}</p>
      ${EVENT_LIST_HTML:-<p class="muted">No calendar constraints today.</p>}
    </section>

    <section class="card">
      <h2>Top Priorities</h2>
      <ul>
        <li><strong>Must-do:</strong> $(printf '%s' "$PRIORITY_MUST" | escape_html)</li>
HTML

if [ -n "$PRIORITY_SHOULD" ]; then
cat >> "$INDEX_FILE" <<HTML
        <li><strong>Should-do:</strong> $(printf '%s' "$PRIORITY_SHOULD" | escape_html)</li>
HTML
fi
if [ -n "$PRIORITY_IF" ]; then
cat >> "$INDEX_FILE" <<HTML
        <li><strong>If there’s time:</strong> $(printf '%s' "$PRIORITY_IF" | escape_html)</li>
HTML
fi

cat >> "$INDEX_FILE" <<HTML
      </ul>
    </section>

    <div class="split">
      <section class="card">
        <h2>Inbox Triage</h2>
HTML
if [ -n "$EMAIL_NEEDS_HTML" ]; then
cat >> "$INDEX_FILE" <<HTML
        <p><strong>Needs attention</strong></p>
        <ul>$EMAIL_NEEDS_HTML</ul>
HTML
fi
if [ -n "$EMAIL_NOTING_HTML" ]; then
cat >> "$INDEX_FILE" <<HTML
        <p><strong>Worth noting</strong></p>
        <ul>$EMAIL_NOTING_HTML</ul>
HTML
fi
cat >> "$INDEX_FILE" <<HTML
        <p class="muted">Ignore bucket: $IGNORE_COUNT items. Total unread: $EMAIL_COUNT.</p>
      </section>

      <section class="card">
        <h2>Weather / Logistics</h2>
        <ul>
          <li>Now: ${TEMP_F}°F, feels like ${FEELS_F}°F.</li>
          <li>Today: ${TODAY_HIGH_F}° / ${TODAY_LOW_F}°.</li>
          <li>Tomorrow: ${TOMORROW_HIGH_F}° / ${TOMORROW_LOW_F}°, rain risk ${TOMORROW_PRECIP}%.</li>
          <li>$WEATHER_CALL</li>
        </ul>
      </section>
    </div>
HTML

if [ "$TODO_COUNT" -gt 0 ]; then
cat >> "$INDEX_FILE" <<HTML
    <section class="card">
      <h2>Task Pressure</h2>
      <p class="muted">$TODO_COUNT due or overdue tasks.</p>
      <ul>$TODO_LIST</ul>
    </section>
HTML
fi

cat >> "$INDEX_FILE" <<HTML
    <section class="card">
      <h2>Habits / Maintenance</h2>
      <p>$HABIT_PATTERN</p>
HTML
if [ -n "$HABIT_LIST_HTML" ]; then
cat >> "$INDEX_FILE" <<HTML
      <ul>$HABIT_LIST_HTML</ul>
HTML
fi
cat >> "$INDEX_FILE" <<HTML
    </section>
HTML

cat >> "$INDEX_FILE" <<HTML
    <section class="card arsenal">
      <h2>Arsenal</h2>
      <ul>${ARSENAL_HTML:-<li class="muted">No fresh Arseblog items pulled.</li>}</ul>
    </section>
HTML

cat >> "$INDEX_FILE" <<HTML
    <section class="card">
      <h2>Pattern to Notice</h2>
      <p>$PATTERN_TEXT</p>
    </section>

    <section class="card">
      <h2>Tomorrow Prep</h2>
      <p>$TOMORROW_SHAPE</p>
    </section>

    <section class="card">
      <h2>Recommended Next Move</h2>
      <p><strong>$NEXT_MOVE</strong></p>
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

echo "{\"emails\":$(jq -R -s -c 'split("\n")[:-1]' "$CURRENT_EMAILS_FILE"),\"tasks\":$TODO_COUNT,\"timestamp\":\"$(date -Iseconds)\"}" > "$STATE_FILE"

cd /home/nik/.openclaw/workspace
git add index.html brief.html .brief-state.json generate-brief-html.sh

git commit -m "Rewrite $BRIEF_TYPE brief structure: $DATE $TIME" 2>/dev/null || true
git push origin main 2>&1 || echo "Push failed"

echo "$BRIEF_TYPE brief generated"
echo "GitHub Pages: https://nikhilist.github.io/morning-brief/"
echo "=== Finished: $(date) ==="
