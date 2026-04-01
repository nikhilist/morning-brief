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

EMAILS_JSON_FILE="$TMP_DIR/emails.json"
gog gmail search 'is:unread' --json --results-only > "$EMAILS_JSON_FILE" 2>/dev/null || echo '[]' > "$EMAILS_JSON_FILE"
jq -r '.[].id' "$EMAILS_JSON_FILE" | sort -u > "$CURRENT_EMAILS_FILE"
comm -23 "$CURRENT_EMAILS_FILE" "$PREV_EMAILS_FILE" > "$NEW_EMAILS_FILE" || :
EMAIL_COUNT=$(jq 'length' "$EMAILS_JSON_FILE")
NEW_COUNT=$(wc -l < "$NEW_EMAILS_FILE" 2>/dev/null | tr -d ' ')
NEW_COUNT=${NEW_COUNT:-0}
LATEST_EMAIL_AT=$(jq -r '.[0].date // empty' "$EMAILS_JSON_FILE")

SCORING_INPUT="$TMP_DIR/scoring-input.jsonl"
: > "$SCORING_INPUT"
SELECTED_IDS_FILE="$TMP_DIR/selected_ids.txt"
cat "$NEW_EMAILS_FILE" > "$SELECTED_IDS_FILE"

if [ "$(wc -l < "$SELECTED_IDS_FILE" | tr -d ' ')" -lt 8 ]; then
  jq -r '.[].id' "$EMAILS_JSON_FILE" | head -n 12 >> "$SELECTED_IDS_FILE"
fi
sort -u "$SELECTED_IDS_FILE" | head -n 12 > "$TMP_DIR/selected_ids_final.txt"

while IFS= read -r id; do
  [ -n "$id" ] || continue
  META_FILE="$TMP_DIR/meta-$id.json"
  FULL_FILE="$TMP_DIR/full-$id.json"
  jq -c --arg id "$id" '.[] | select(.id == $id)' "$EMAILS_JSON_FILE" > "$META_FILE"
  [ -s "$META_FILE" ] || continue
  gog gmail get "$id" --json --results-only > "$FULL_FILE" 2>/dev/null || echo '{}' > "$FULL_FILE"
  # Create combined JSON for this email
  jq -c --arg id "$id" '.[] | select(.id == $id)' "$EMAILS_JSON_FILE" | jq -c \
    --arg is_new "$(grep -qx "$id" "$NEW_EMAILS_FILE" && echo true || echo false)" \
    --slurpfile full "$FULL_FILE" \
    '{
      id: .id,
      date: .date,
      from: (.from // "Unknown"),
      subject: (.subject // "(no subject)"),
      labels: (.labels // []),
      is_new: ($is_new == "true"),
      body: ($full[0].body // "")
    }' >> "$SCORING_INPUT" 2>/dev/null || true
done < "$TMP_DIR/selected_ids_final.txt"

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
        (if (.from_lower | test("school|teacher|dojo|doctor|medical|calendar|airline|delta|jetblue|united|american airlines|billing|invoice|payment due|appointment|daycare|camp|soccer|karate|swim|princeton|amazon|monarch")) then 45 else 0 end) +
        (if (.subject_lower | test("action required|payment due|appointment|schedule|shared a post|message from|flight|receipt|invoice|statement|renewal|reminder|deadline|registration|enroll|school|doctor|medical|karate|soccer|swim|delivery|order|return|account|trip")) then 30 else 0 end) +
        (if (.body_lower | test("action required|please respond|please review|complete your registration|confirm|scheduled|appointment|invoice|payment due|shared a post|teacher|school|classdojo|karate|soccer|swim|flight|boarding|reservation|delivered|out for delivery|tracking|return window|statement available|budget|transaction")) then 30 else 0 end) +
        (if (.body_lower | test("unsubscribe|manage preferences|view in browser|shop now|limited time|sale ends|sponsored|advertisement|recommended for you|you may also like")) then -40 else 0 end) +
        (if (.from_lower | test("newsletter|marketing|promo|deals|sale|substack|medium|linkedin|instagram|facebook|x.com|twitter|huckberry|the athletic|arsemail")) then -50 else 0 end) +
        (if ((.subject_lower | test("weekly round(up)?|daily digest|newsletter|top stories|news update|breaking news")) and (.body_lower | test("unsubscribe|manage preferences|view in browser"))) then -60 else 0 end)
      )
    }) |
    map(. + {
      bucket: (if .score >= 65 then "needs" elif .score >= 30 then "noting" else "ignore" end),
      reason: (
        if .score >= 65 then
          (if (.body_lower | test("action required|please respond|payment due|confirm|complete your registration|appointment|flight|teacher|shared a post|school|karate|soccer|swim|delivered|tracking|statement available|budget|transaction"))
           then "action or real-world relevance"
           else "likely worth your attention"
           end)
        elif .score >= 30 then "informational but not urgent"
        else "junk/noise after reading"
        end
      )
    })
  ' "$SCORING_INPUT" > "$TMP_DIR/scored_emails.json"
fi

NEEDS_JSON=$(jq '[.[] | select(.bucket == "needs")][0:5]' "$TMP_DIR/scored_emails.json")
NOTING_JSON=$(jq '[.[] | select(.bucket == "noting")][0:3]' "$TMP_DIR/scored_emails.json")
IGNORE_COUNT=$(jq '[.[] | select(.bucket == "ignore")] | length' "$TMP_DIR/scored_emails.json")
REVIEWED_COUNT=$(jq 'length' "$TMP_DIR/scored_emails.json")
NEW_REVIEWED_COUNT=$(jq '[.[] | select(.is_new == true)] | length' "$TMP_DIR/scored_emails.json")
BACKLOG_REVIEWED_COUNT=$(jq '[.[] | select(.is_new != true)] | length' "$TMP_DIR/scored_emails.json")

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
  <p><strong>${NEW_COUNT}</strong> new unread since the last brief. Reviewed ${NEW_REVIEWED_COUNT} new email bodies and ${BACKLOG_REVIEWED_COUNT} older unread for context.</p>
  <p><strong>Actually useful</strong></p>
  <ul>$EMAIL_NEEDS_HTML</ul>
</section>
HTML
  fi
else
  cat <<HTML
<section class="card">
  <h2>Inbox Triage</h2>
  <p class="muted">Reviewed ${NEW_REVIEWED_COUNT} new email bodies and ${BACKLOG_REVIEWED_COUNT} older unread emails, not just subject lines.</p>
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
