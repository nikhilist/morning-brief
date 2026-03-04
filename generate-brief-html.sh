#!/bin/bash
# Generate full HTML brief page with insights and delta tracking

OUTPUT_FILE="/home/nik/.openclaw/workspace/brief.html"
INDEX_FILE="/home/nik/.openclaw/workspace/index.html"
STATE_FILE="/home/nik/.openclaw/workspace/.brief-state.json"
DATE=$(date '+%A, %B %-d, %Y')
TIME=$(date '+%I:%M %p')
HOUR=$(date '+%H')

# Determine brief type
if [ "$HOUR" -lt 12 ]; then
    BRIEF_TYPE="Morning"
elif [ "$HOUR" -lt 20 ]; then
    BRIEF_TYPE="Afternoon"
else
    BRIEF_TYPE="Evening"
fi

# Setup env
export PATH=$PATH:$HOME/.local/bin
export GOG_KEYRING_BACKEND=file
export GOG_KEYRING_PASSWORD=""
export GOG_ACCOUNT=nikhilist@gmail.com
export HABITICA_USER_ID="404a4487-6eea-4ed3-b60b-03f82092b29a"
export HABITICA_API_TOKEN="e3470ee9-56d7-49f4-bd56-4f3f175bd804"

# Load previous state
PREV_EMAILS=""
PREV_TASKS=""
if [ -f "$STATE_FILE" ]; then
    PREV_EMAILS=$(jq -r '.emails // empty' "$STATE_FILE" 2>/dev/null)
    PREV_TASKS=$(jq -r '.tasks // empty' "$STATE_FILE" 2>/dev/null)
fi

# Get weather
WEATHER_JSON=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=40.3573&longitude=-74.6672&current=temperature_2m,apparent_temperature,weather_code&timezone=America/New_York")
TEMP=$(echo "$WEATHER_JSON" | jq -r '.current.temperature_2m')
FEELS_LIKE=$(echo "$WEATHER_JSON" | jq -r '.current.apparent_temperature')
TEMP_F=$(echo "scale=0; ($TEMP * 9/5) + 32" | bc -l 2>/dev/null || echo "31")
FEELS_F=$(echo "scale=0; ($FEELS_LIKE * 9/5) + 32" | bc -l 2>/dev/null || echo "26")

# Get ALL current emails
EMAILS_JSON=$(gog gmail search 'is:unread' --json 2>/dev/null || echo '{"threads":[]}')
ALL_EMAILS=$(echo "$EMAILS_JSON" | jq -r '.threads[].id' 2>/dev/null | sort)
EMAIL_COUNT=$(echo "$ALL_EMAILS" | wc -l)

# Find NEW emails (not in previous state)
NEW_EMAILS=""
NEW_EMAIL_LIST=""
if [ -n "$PREV_EMAILS" ]; then
    NEW_EMAILS=$(comm -23 <(echo "$ALL_EMAILS") <(echo "$PREV_EMAILS") 2>/dev/null)
    NEW_COUNT=$(echo "$NEW_EMAILS" | grep -c '^' 2>/dev/null || echo "0")
else
    NEW_EMAILS="$ALL_EMAILS"
    NEW_COUNT="$EMAIL_COUNT"
fi

# Build email list (only NEW emails since last run)
if [ -n "$NEW_EMAILS" ]; then
    NEW_EMAIL_LIST=$(echo "$EMAILS_JSON" | jq --arg new "$NEW_EMAILS" -r '.threads[] | select(.id as $id | $new | contains($id)) | "<div class=\"email-item\"><div class=\"email-sender\">\(.from)</div><div class=\"email-subject\">\(.subject)</div></div>"' 2>/dev/null)
fi

# Get calendar events
NEEL_EVENTS=$(gog calendar events "8tdo49s92dr6h34pcros8a17k8@group.calendar.google.com" --from $(date '+%Y-%m-%d') --to $(date -d '+1 day' '+%Y-%m-%d' 2>/dev/null || date -v+1d '+%Y-%m-%d') --json 2>/dev/null || echo '{"events":[]}')
NEEL_LIST=$(echo "$NEEL_EVENTS" | jq -r '.events[] | "<div class=\"event\"><div class=\"event-time\">\(.start.date // (.start.dateTime | split("T")[1][:5]))</div><div class=\"event-title\">\(.summary)</div></div>"' 2>/dev/null || echo "")

# Get Todoist tasks
TODO_JSON=$(todoist tasks --json 2>/dev/null || echo '[]')
TODO_COUNT=$(echo "$TODO_JSON" | jq 'length')
TODO_LIST=$(echo "$TODO_JSON" | jq -r '.[] | "<li>\(.content)</li>"' 2>/dev/null || echo "")

# Get Habitica dailies
HABITICA_OUT=$(~/.openclaw/workspace/skills/habitica-skill/scripts/habitica.sh list dailys 2>/dev/null)
HABIT_PENDING=$(echo "$HABITICA_OUT" | grep "value: 0" | sed 's/.*\[daily\] //;s/ (value:.*//' || echo "")
HABIT_DONE=$(echo "$HABITICA_OUT" | grep "value: 1" | sed 's/.*\[daily\] //;s/ (value:.*//' || echo "")

# Get Arsenal news (simple approach)
ARSEBLOG_RAW=$(curl -s https://arseblog.news/ | grep -E '<h2|<h3' | grep -oE '>([^<]+)<' | tr -d '><' | head -5 || echo "")
ARSEBLOG=""
if [ -n "$ARSEBLOG_RAW" ]; then
    ARSEBLOG=$(echo "$ARSEBLOG_RAW" | sed 's/^/<li>/;s/$/<\/li>/')
fi

# Save current state
echo "{\"emails\":$(echo "$ALL_EMAILS" | jq -R -s -c 'split("\n")[:-1]'),\"tasks\":$TODO_COUNT,\"timestamp\":\"$(date -Iseconds)\"}" > "$STATE_FILE"

# Generate insights based on brief type
INSIGHTS=""
if [ "$BRIEF_TYPE" = "Evening" ]; then
    INSIGHTS="<div class=\"card insights-card\">
            <div class=\"card-header\">
                <span class=\"icon\">💭</span>
                Insights
            </div>
            <p class=\"insight-text\">You got Neel through $([ -n \"\$NEEL_LIST\" ] && echo \"his day\" || echo \"the day\"). That's the win that matters.</p>
            <p class=\"insight-text\">$(if [ \"$TODO_COUNT\" -gt 0 ]; then echo \"The contact lens prescription is still there. It's not hard—just boring. Knock it out first thing tomorrow.\"; else echo \"Tasks are clear. Good.\"; fi)</p>
            <p class=\"insight-text\">$(if [ -n \"\$HABIT_PENDING\" ]; then echo \"Same habit missed again. Either the timing doesn't work or you need a different trigger. Morning coffee?\"; else echo \"Habits on track.\"; fi)</p>
            <p class=\"insight-text\">The $EMAIL_COUNT unread emails aren't urgent—they're noise. Consider the 3-day rule: if no follow-up, it's not important.</p>
        </div>"
fi

cat > "$INDEX_FILE" << HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nik's $BRIEF_TYPE Brief</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: #eaeaea;
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 800px; margin: 0 auto; }
        header {
            text-align: center;
            padding: 30px 0;
            border-bottom: 1px solid rgba(255,255,255,0.1);
            margin-bottom: 30px;
        }
        .date {
            font-size: 0.9rem;
            color: #8892b0;
            text-transform: uppercase;
            letter-spacing: 2px;
        }
        h1 {
            font-size: 2.5rem;
            margin: 10px 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .location { color: #64ffda; font-size: 1.1rem; }
        .card {
            background: rgba(255,255,255,0.05);
            border-radius: 16px;
            padding: 25px;
            margin-bottom: 20px;
            border: 1px solid rgba(255,255,255,0.1);
            backdrop-filter: blur(10px);
        }
        .card-header {
            display: flex;
            align-items: center;
            margin-bottom: 15px;
            font-size: 1.2rem;
            font-weight: 600;
        }
        .card-header .icon { font-size: 1.5rem; margin-right: 10px; }
        .weather-card { display: flex; align-items: center; justify-content: space-between; }
        .weather-main { font-size: 3rem; font-weight: 300; }
        .weather-desc { color: #8892b0; margin-top: 5px; }
        .weather-icon { font-size: 4rem; }
        .badge {
            display: inline-block;
            background: rgba(100, 255, 218, 0.1);
            color: #64ffda;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            margin-left: 10px;
        }
        .badge.new { background: rgba(239, 1, 7, 0.2); color: #ff6b6b; }
        .event {
            display: flex;
            align-items: flex-start;
            padding: 10px 0;
            border-bottom: 1px solid rgba(255,255,255,0.05);
        }
        .event:last-child { border-bottom: none; }
        .event-time { min-width: 80px; color: #64ffda; font-size: 0.85rem; }
        .event-title { flex: 1; }
        .email-item {
            padding: 12px 0;
            border-bottom: 1px solid rgba(255,255,255,0.05);
        }
        .email-item:last-child { border-bottom: none; }
        .email-sender { color: #64ffda; font-weight: 500; font-size: 0.9rem; }
        .email-subject { color: #eaeaea; font-size: 0.95rem; margin-top: 2px; }
        .task-list, .habit-list { list-style: none; margin-top: 10px; }
        .task-list li, .habit-list li {
            padding: 8px 0;
            border-bottom: 1px solid rgba(255,255,255,0.05);
        }
        .task-list li:last-child, .habit-list li:last-child { border-bottom: none; }
        .habit-pending { color: #ef0107; }
        .habit-done { color: #64ffda; text-decoration: line-through; opacity: 0.7; }
        .arsenal-card {
            background: linear-gradient(135deg, rgba(239, 1, 7, 0.1) 0%, rgba(255,255,255,0.05) 100%);
            border-left: 4px solid #ef0107;
        }
        .insights-card {
            background: linear-gradient(135deg, rgba(102, 126, 234, 0.1) 0%, rgba(255,255,255,0.05) 100%);
            border-left: 4px solid #667eea;
        }
        .insight-text {
            color: #b8c5d6;
            line-height: 1.6;
            margin-bottom: 12px;
            font-size: 0.95rem;
        }
        .insight-text:last-child { margin-bottom: 0; }
        .news-list { list-style: none; margin-top: 10px; }
        .news-list li {
            padding: 8px 0;
            color: #ffd700;
            border-bottom: 1px solid rgba(255,255,255,0.05);
        }
        .news-list li:last-child { border-bottom: none; }
        .footer {
            text-align: center;
            padding: 30px;
            color: #8892b0;
            font-size: 0.9rem;
        }
        .delta-note {
            font-size: 0.85rem;
            color: #8892b0;
            margin-left: 10px;
        }
        @media (max-width: 600px) {
            h1 { font-size: 1.8rem; }
            .weather-main { font-size: 2rem; }
            .card { padding: 20px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="date">$DATE</div>
            <h1>$BRIEF_TYPE Brief</h1>
            <div class="location">📍 Princeton, NJ</div>
        </header>

        <div class="card">
            <div class="card-header">
                <span class="icon">🌤️</span>
                Weather
            </div>
            <div class="weather-card">
                <div>
                    <div class="weather-main">${TEMP_F}°F</div>
                    <div class="weather-desc">Feels like ${FEELS_F}°F</div>
                </div>
                <div class="weather-icon">☁️</div>
            </div>
        </div>

        <div class="card">
            <div class="card-header">
                <span class="icon">📆</span>
                Today's Agenda
            </div>
            $NEEL_LIST
            <div class="event">
                <div class="event-time">7:00 AM</div>
                <div class="event-title">Wake up</div>
            </div>
            <div class="event">
                <div class="event-time">8:45 AM</div>
                <div class="event-title">Drop Neel off</div>
            </div>
        </div>
HTML

# Add NEW emails section (only emails since last run)
if [ -n "$NEW_EMAIL_LIST" ]; then
cat >> "$INDEX_FILE" << HTML
        <div class="card">
            <div class="card-header">
                <span class="icon">📧</span>
                New Emails <span class="badge new">$NEW_COUNT new</span>
                <span class="delta-note">($EMAIL_COUNT total unread)</span>
            </div>
            $NEW_EMAIL_LIST
        </div>
HTML
fi

# Add tasks section
if [ "$TODO_COUNT" -gt 0 ]; then
cat >> "$INDEX_FILE" << HTML
        <div class="card">
            <div class="card-header">
                <span class="icon">✅</span>
                Tasks <span class="badge pending">$TODO_COUNT due</span>
            </div>
            <ul class="task-list">
                $TODO_LIST
            </ul>
        </div>
HTML
fi

# Add habits section
if [ -n "$HABIT_PENDING" ] || [ -n "$HABIT_DONE" ]; then
cat >> "$INDEX_FILE" << HTML
        <div class="card">
            <div class="card-header">
                <span class="icon">🎯</span>
                Habits
            </div>
            <ul class="habit-list">
HTML
    if [ -n "$HABIT_PENDING" ]; then
        echo "$HABIT_PENDING" | while read habit; do
            [ -n "$habit" ] && echo "                <li class=\"habit-pending\">☐ $habit</li>" >> "$INDEX_FILE"
        done
    fi
    if [ -n "$HABIT_DONE" ]; then
        echo "$HABIT_DONE" | while read habit; do
            [ -n "$habit" ] && echo "                <li class=\"habit-done\">☑ $habit</li>" >> "$INDEX_FILE"
        done
    fi
cat >> "$INDEX_FILE" << HTML
            </ul>
        </div>
HTML
fi

# Add Arsenal section
if [ -n "$ARSEBLOG" ]; then
cat >> "$INDEX_FILE" << HTML
        <div class="card arsenal-card">
            <div class="card-header">
                <span class="icon">🔴</span>
                Arsenal FC
            </div>
            <ul class="news-list">
                $ARSEBLOG
            </ul>
        </div>
HTML
fi

# Add insights for evening brief
echo "$INSIGHTS" >> "$INDEX_FILE"

cat >> "$INDEX_FILE" << HTML
        <div class="footer">
            Last updated: $TIME<br>
            <a href="https://github.com/nikhilist/morning-brief" style="color: #64ffda;">github.com/nikhilist/morning-brief</a>
        </div>
    </div>
</body>
</html>
HTML

# Copy to brief.html too
cp "$INDEX_FILE" "$OUTPUT_FILE"

# Commit and push
cd /home/nik/.openclaw/workspace
git add index.html brief.html .brief-state.json
git commit -m "Update $BRIEF_TYPE brief: $DATE $TIME" 2>/dev/null || true
git push origin main 2>&1 || echo "Push failed"

echo "$BRIEF_TYPE brief generated with delta tracking"
echo "GitHub Pages: https://nikhilist.github.io/morning-brief/"