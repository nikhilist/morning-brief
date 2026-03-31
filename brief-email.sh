#!/bin/bash
set -euo pipefail
export TZ="America/New_York"
export GOG_KEYRING_BACKEND=file
export GOG_KEYRING_PASSWORD=""
export GOG_ACCOUNT=nikhilist@gmail.com
source /home/nik/.openclaw/workspace/brief-lib.sh

STATE_FILE="/home/nik/.openclaw/workspace/.brief-state.json"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
PREV_EMAILS_FILE="$TMP_DIR/prev_emails.txt"
CURRENT_EMAILS_FILE="$TMP_DIR/current_emails.txt"
NEW_EMAILS_FILE="$TMP_DIR/new_emails.txt"

if [ -f "$STATE_FILE" ]; then
  jq -r '.emails[]? // empty' "$STATE_FILE" 2>/dev/null | sort -u > "$PREV_EMAILS_FILE" || :
else
  : > "$PREV_EMAILS_FILE"
fi

EMAILS_JSON=$(gog gmail search 'is:unread' --json --results-only 2>/dev/null || echo '[]')
echo "$EMAILS_JSON" | jq -r '.[].id' | sort -u > "$CURRENT_EMAILS_FILE"
comm -23 "$CURRENT_EMAILS_FILE" "$PREV_EMAILS_FILE" > "$NEW_EMAILS_FILE" || :
EMAIL_COUNT=$(echo "$EMAILS_JSON" | jq 'length')
NEW_COUNT=$(wc -l < "$NEW_EMAILS_FILE" 2>/dev/null | tr -d ' ')
NEW_COUNT=${NEW_COUNT:-0}
LATEST_EMAIL_AT=$(echo "$EMAILS_JSON" | jq -r '.[0].date // empty')

SCORING_INPUT="$TMP_DIR/scoring-input.jsonl"
: > "$SCORING_INPUT"

while IFS= read -r id; do
  [ -n "$id" ] || continue
  META=$(echo "$EMAILS_JSON" | jq -c --arg id "$id" '.[] | select(.id == $id)')
  FULL=$(gog gmail get "$id" --json --results-only 2>/dev/null || echo '{}')
  jq -cn \
    --argjson meta "$META" \
    --argjson full "$FULL" \
    '{
      id: ($meta.id // ""),
      date: ($meta.date // ""),
      from: ($meta.from // "Unknown"),
      subject: ($meta.subject // "(no subject)"),
      labels: ($meta.labels // []),
      body: (($full.body // "") | tostring)
    }' >> "$SCORING_INPUT"
done < <(head -n 12 "$NEW_EMAILS_FILE")

if [ ! -s "$SCORING_INPUT" ]; then
  echo '[]' > "$TMP_DIR/scored_emails.json"
else
  jq -s '
    map(. + {
      body_lower: ((.body // "") | ascii_downcase),
      subject_lower: ((.subject // "") | ascii_downcase),
      from_lower: ((.from // "") | ascii_downcase)
    }) |
    map(. + {
      score: (
        0 +
        (if (.from_lower | test("school|teacher|dojo|doctor|medical|calendar|airline|delta|jetblue|united|american airlines|billing|invoice|payment due|appointment|daycare|camp|soccer|karate|swim|princeton")) then 50 else 0 end) +
        (if (.subject_lower | test("action required|payment due|appointment|schedule|shared a post|message from|flight|receipt|invoice|statement|renewal|reminder|deadline|registration|enroll|school|doctor|medical|karate|soccer|swim")) then 35 else 0 end) +
        (if (.body_lower | test("action required|please respond|please review|complete your registration|confirm|scheduled|appointment|invoice|payment due|shared a post|teacher|school|classdojo|karate|soccer|swim|flight|boarding|reservation")) then 35 else 0 end) +
        (if (.from_lower | test("noreply|no-reply|newsletter|marketing|promo|deals|sale|substack|medium|linkedin|instagram|facebook|x.com|twitter|huckberry|the athletic|arsemail")) then -45 else 0 end) +
        (if (.body_lower | test("unsubscribe|manage preferences|view in browser|shop now|limited time|sale ends|sponsored|advertisement")) then -35 else 0 end)
      )
    }) |
    map(. + {
      bucket: (if .score >= 70 then "needs" elif .score >= 25 then "noting" else "ignore" end),
      reason: (
        if .score >= 70 then
          (if (.body_lower | test("action required|please respond|payment due|confirm|complete your registration|appointment|flight|teacher|shared a post|school|karate|soccer|swim"))
           then "useful after reading"
           else "probably useful"
           end)
        elif .score >= 25 then "maybe useful"
        else "looks like junk/noise"
        end
      )
    })
  ' "$SCORING_INPUT" > "$TMP_DIR/scored_emails.json"
fi

NEEDS_JSON=$(jq '[.[] | select(.bucket == "needs")][0:5]' "$TMP_DIR/scored_emails.json")
NOTING_JSON=$(jq '[.[] | select(.bucket == "noting")][0:3]' "$TMP_DIR/scored_emails.json")
IGNORE_COUNT=$(jq '[.[] | select(.bucket == "ignore")] | length' "$TMP_DIR/scored_emails.json")
REVIEWED_COUNT=$(jq 'length' "$TMP_DIR/scored_emails.json")

render_email_bucket() {
  local json="$1"
  echo "$json" | jq -r '.[] | "<li><strong>" + (.from // "Unknown") + "</strong> — " + (.subject // "(no subject)") + " <span class=\"muted\">(" + (.reason // "") + ")</span></li>"' 2>/dev/null || true
}
EMAIL_NEEDS_HTML=$(render_email_bucket "$NEEDS_JSON")
EMAIL_NOTING_HTML=$(render_email_bucket "$NOTING_JSON")

MEANINGFUL_DELTA=0
if [ "$NEW_COUNT" -gt 0 ] && [ -n "$EMAIL_NEEDS_HTML" ]; then
  MEANINGFUL_DELTA=1
fi

if [ "$(brief_mode)" = "delta" ]; then
  if [ "$MEANINGFUL_DELTA" -eq 1 ]; then
    cat <<HTML
<section class="card">
  <h2>Inbox</h2>
  <p><strong>${NEW_COUNT}</strong> new unread since the last brief. Reviewed ${REVIEWED_COUNT} new email bodies.</p>
  <p><strong>Actually useful</strong></p>
  <ul>$EMAIL_NEEDS_HTML</ul>
</section>
HTML
  fi
else
  cat <<HTML
<section class="card">
  <h2>Inbox Triage</h2>
  <p class="muted">Reviewed ${REVIEWED_COUNT} new email bodies, not just subject lines.</p>
HTML
  if [ -n "$EMAIL_NEEDS_HTML" ]; then
    cat <<HTML
  <p><strong>Actually useful</strong></p>
  <ul>$EMAIL_NEEDS_HTML</ul>
HTML
  fi
  if [ -n "$EMAIL_NOTING_HTML" ]; then
    cat <<HTML
  <p><strong>Maybe useful</strong></p>
  <ul>$EMAIL_NOTING_HTML</ul>
HTML
  fi
  cat <<HTML
  <p class="muted">Ignored as likely junk/noise: $IGNORE_COUNT. Total unread: $EMAIL_COUNT.</p>
</section>
HTML
fi
TOP_NEEDS=$(echo "$NEEDS_JSON" | jq -r 'map((.from // "Unknown") + " — " + (.subject // "(no subject)")) | join(" | ")' 2>/dev/null)
USEFUL_COUNT=$(echo "$NEEDS_JSON" | jq 'length')
brief_meta SUMMARY "${USEFUL_COUNT} of ${NEW_COUNT} new unread emails look actually useful after reading the email bodies."
brief_meta EMAIL_IDS "$(jq -R -s -c 'split("\n")[:-1]' "$CURRENT_EMAILS_FILE")"
brief_meta NEEDS_TOP "${TOP_NEEDS}"
brief_meta LATEST_EMAIL_AT "${LATEST_EMAIL_AT}"
