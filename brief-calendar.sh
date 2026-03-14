#!/bin/bash
set -euo pipefail
export TZ="America/New_York"
export GOG_KEYRING_BACKEND=file
export GOG_KEYRING_PASSWORD=""
export GOG_ACCOUNT=nikhilist@gmail.com

TODAY_START=$(date '+%Y-%m-%d')
TODAY_END=$(date -d '+1 day' '+%Y-%m-%d' 2>/dev/null || date -v+1d '+%Y-%m-%d')
TOMORROW_START=$(date -d '+1 day' '+%Y-%m-%d' 2>/dev/null || date -v+1d '+%Y-%m-%d')
TOMORROW_END=$(date -d '+2 day' '+%Y-%m-%d' 2>/dev/null || date -v+2d '+%Y-%m-%d')

NIK_EVENTS=$(gog calendar events "nikhilist@gmail.com" --from "$TODAY_START" --to "$TODAY_END" --json 2>/dev/null || echo '{"events":[]}')
NEEL_EVENTS=$(gog calendar events "8tdo49s92dr6h34pcros8a17k8@group.calendar.google.com" --from "$TODAY_START" --to "$TODAY_END" --json 2>/dev/null || echo '{"events":[]}')
ARSENAL_EVENTS=$(gog calendar events "08ac8665d76573fd7cfcb0e0cb13ed3a951e59b7b1c4c6eabc9adaae8a74e615@group.calendar.google.com" --from "$TODAY_START" --to "$TODAY_END" --json 2>/dev/null || echo '{"events":[]}')
ALL_EVENTS=$(jq -s '{events: (.[0].events + .[1].events + .[2].events)}' <(echo "$NIK_EVENTS") <(echo "$NEEL_EVENTS") <(echo "$ARSENAL_EVENTS") 2>/dev/null || echo '{"events":[]}')
EVENT_LIST_HTML=$(echo "$ALL_EVENTS" | jq -r '.events | sort_by(.start.dateTime // .start.date // "")[] | "<div class=""event""><div class=""event-time"">" + (.start.date // ((.start.dateTime | split("T")[1])[:5])) + "</div><div class=""event-title""><span class=""calendar-tag"">" + (.organizer.email // "calendar") + "</span> " + (.summary // "Untitled") + "</div></div>"' 2>/dev/null || true)
DAY_SHAPE=$(echo "$ALL_EVENTS" | jq -r '.events | sort_by(.start.dateTime // .start.date // "") | if length == 0 then "No real calendar constraints today." else map(.summary) | join(" • ") end' 2>/dev/null)

TOMORROW_EVENTS=$(jq -s '{events: (.[0].events + .[1].events + .[2].events)}' \
  <(gog calendar events "nikhilist@gmail.com" --from "$TOMORROW_START" --to "$TOMORROW_END" --json 2>/dev/null || echo '{"events":[]}') \
  <(gog calendar events "8tdo49s92dr6h34pcros8a17k8@group.calendar.google.com" --from "$TOMORROW_START" --to "$TOMORROW_END" --json 2>/dev/null || echo '{"events":[]}') \
  <(gog calendar events "08ac8665d76573fd7cfcb0e0cb13ed3a951e59b7b1c4c6eabc9adaae8a74e615@group.calendar.google.com" --from "$TOMORROW_START" --to "$TOMORROW_END" --json 2>/dev/null || echo '{"events":[]}') 2>/dev/null || echo '{"events":[]}')
TOMORROW_SHAPE=$(echo "$TOMORROW_EVENTS" | jq -r '.events | sort_by(.start.dateTime // .start.date // "") | if length == 0 then "Tomorrow is open right now." else map(.summary) | join(" • ") end' 2>/dev/null)

cat <<HTML
<section class="card">
  <h2>Day at a Glance</h2>
  <p>${DAY_SHAPE}</p>
  ${EVENT_LIST_HTML:-<p class="muted">No calendar constraints today.</p>}
</section>
__SUMMARY__${DAY_SHAPE}
__TOMORROW__${TOMORROW_SHAPE}
HTML
