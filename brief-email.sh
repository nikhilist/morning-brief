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

render_email_bucket() {
  local json="$1"
  echo "$json" | jq -r '.[] | "<li><strong>" + (.from // "Unknown") + "</strong> — " + (.subject // "(no subject)") + "</li>"' 2>/dev/null || true
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
  <p><strong>${NEW_COUNT}</strong> new unread since the last brief.</p>
  <p><strong>New signal</strong></p>
  <ul>$EMAIL_NEEDS_HTML</ul>
</section>
HTML
  fi
else
  cat <<HTML
<section class="card">
  <h2>Inbox Triage</h2>
HTML
  if [ -n "$EMAIL_NEEDS_HTML" ]; then
    cat <<HTML
  <p><strong>Needs attention</strong></p>
  <ul>$EMAIL_NEEDS_HTML</ul>
HTML
  fi
  if [ -n "$EMAIL_NOTING_HTML" ]; then
    cat <<HTML
  <p><strong>Worth noting</strong></p>
  <ul>$EMAIL_NOTING_HTML</ul>
HTML
  fi
  cat <<HTML
  <p class="muted">Ignore bucket: $IGNORE_COUNT items. Total unread: $EMAIL_COUNT.</p>
</section>
HTML
fi
TOP_NEEDS=$(echo "$NEEDS_JSON" | jq -r 'map((.from // "Unknown") + " — " + (.subject // "(no subject)")) | join(" | ")' 2>/dev/null)
brief_meta SUMMARY "${NEW_COUNT} new unread emails since the last brief; most should be triaged, not read end-to-end."
brief_meta EMAIL_IDS "$(jq -R -s -c 'split("\n")[:-1]' "$CURRENT_EMAILS_FILE")"
brief_meta NEEDS_TOP "${TOP_NEEDS}"
