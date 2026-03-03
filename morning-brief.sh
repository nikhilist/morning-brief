#!/bin/bash
# Morning Brief Script for Nik
# Runs at 6am, sends brief to Telegram

# Config
LOCATION="Princeton,NJ"
TELEGRAM_CHAT_ID="935335162"  # Nik's Telegram ID

# Get weather (with 10s timeout)
WEATHER=$(curl -s --max-time 10 "wttr.in/${LOCATION}?format=%l:+%c+%t+(feels+like+%f),+%w+wind" 2>/dev/null || echo "Weather: Unable to fetch")

# Get calendar events for today
CALENDAR_JSON=$(openclaw calendar list --today --json 2>/dev/null || echo "[]")

# Get unread emails (limit 5)
EMAIL_JSON=$(openclaw gmail list --unread --limit 5 --json 2>/dev/null || echo "[]")

# Get Todoist tasks
TODO_JSON=$(openclaw todoist list --json 2>/dev/null || echo "[]")

# Today's date
TODAY=$(date '+%A, %B %-d')

# Build the brief
BRIEF=$(cat <<EOF
📅 **Morning Brief — ${TODAY}**
**Princeton, NJ** · Nik's Day Ahead

---

🌤️ **Weather**
${WEATHER}

---

📆 **Today's Agenda**
EOF
)

# Parse calendar events
if [ "$CALENDAR_JSON" != "[]" ] && [ -n "$CALENDAR_JSON" ]; then
    EVENTS=$(echo "$CALENDAR_JSON" | jq -r '.[] | "- \(.start | sub(\"T.*\"; \"\")) — \(.summary)"' 2>/dev/null || echo "")
    if [ -n "$EVENTS" ]; then
        BRIEF="${BRIEF}
${EVENTS}"
    else
        BRIEF="${BRIEF}
No events scheduled."
    fi
else
    BRIEF="${BRIEF}
No events scheduled."
fi

# Add morning routine
BRIEF="${BRIEF}
- 7:00 AM — Wake up
- 8:45 AM — Drop Neel off *(~30 min window)*"

# Parse emails
BRIEF="${BRIEF}

---

📧 **Email (Unread)**"

if [ "$EMAIL_JSON" != "[]" ] && [ -n "$EMAIL_JSON" ]; then
    EMAIL_COUNT=$(echo "$EMAIL_JSON" | jq 'length' 2>/dev/null || echo "0")
    if [ "$EMAIL_COUNT" -gt 0 ]; then
        EMAILS=$(echo "$EMAIL_JSON" | jq -r '.[] | "- \(.from // \"Unknown\") — \(.subject // \"No subject\")"' 2>/dev/null)
        BRIEF="${BRIEF}
${EMAILS}"
    else
        BRIEF="${BRIEF}
No unread emails."
    fi
else
    BRIEF="${BRIEF}
No unread emails."
fi

# Parse Todoist tasks
BRIEF="${BRIEF}

---

✅ **Tasks (Todoist)**"

if [ "$TODO_JSON" != "[]" ] && [ -n "$TODO_JSON" ]; then
    TASK_COUNT=$(echo "$TODO_JSON" | jq 'length' 2>/dev/null || echo "0")
    if [ "$TASK_COUNT" -gt 0 ]; then
        TASKS=$(echo "$TODO_JSON" | jq -r '.[] | "- [ ] \(.content)"' 2>/dev/null)
        BRIEF="${BRIEF}
${TASKS}"
    else
        BRIEF="${BRIEF}
No pending tasks — you're all caught up!"
    fi
else
    BRIEF="${BRIEF}
No pending tasks — you're all caught up!"
fi

# Footer
BRIEF="${BRIEF}

---

_Good morning — have a great day!_"

# Save to temp file and send
TMPFILE=$(mktemp)
echo "$BRIEF" > "$TMPFILE"
openclaw message send --channel telegram --target "$TELEGRAM_CHAT_ID" --file "$TMPFILE"
rm "$TMPFILE"

echo "Morning brief sent at $(date)"
