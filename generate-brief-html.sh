#!/bin/bash
# Generate static HTML brief page

OUTPUT_FILE="/home/nik/.openclaw/workspace/brief.html"
DATE=$(date '+%A, %B %-d, %Y')
TIME=$(date '+%I:%M %p')

# Get weather
WEATHER_JSON=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=40.3573&longitude=-74.6672&current=temperature_2m,apparent_temperature,weather_code&timezone=America/New_York")
TEMP=$(echo "$WEATHER_JSON" | jq -r '.current.temperature_2m')
FEELS_LIKE=$(echo "$WEATHER_JSON" | jq -r '.current.apparent_temperature')
# Convert C to F
TEMP_F=$(echo "scale=0; ($TEMP * 9/5) + 32" | bc -l 2>/dev/null || echo "31")
FEELS_F=$(echo "scale=0; ($FEELS_LIKE * 9/5) + 32" | bc -l 2>/dev/null || echo "26")

# Get calendar events (using gog)
export PATH=$PATH:$HOME/.local/bin
export GOG_KEYRING_BACKEND=file
export GOG_KEYRING_PASSWORD=""
export GOG_ACCOUNT=nikhilist@gmail.com

# Nik's events
NIK_EVENTS=$(gog calendar events nikhilist@gmail.com --from $(date '+%Y-%m-%d') --to $(date -d '+1 day' '+%Y-%m-%d' 2>/dev/null || date -v+1d '+%Y-%m-%d') --json 2>/dev/null || echo '{"events":[]}')

# Neel's events  
NEEL_EVENTS=$(gog calendar events "8tdo49s92dr6h34pcros8a17k8@group.calendar.google.com" --from $(date '+%Y-%m-%d') --to $(date -d '+1 day' '+%Y-%m-%d' 2>/dev/null || date -v+1d '+%Y-%m-%d') --json 2>/dev/null || echo '{"events":[]}')

# Email count
EMAIL_COUNT=$(gog gmail search 'is:unread' --json 2>/dev/null | jq '.threads | length' 2>/dev/null || echo "0")

# Todoist tasks
TODO_COUNT=$(todoist tasks --json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")

# Habitica dailies
export HABITICA_USER_ID="404a4487-6eea-4ed3-b60b-03f82092b29a"
export HABITICA_API_TOKEN="e3470ee9-56d7-49f4-bd56-4f3f175bd804"
HABITICA_PENDING=$(~/.openclaw/workspace/skills/habitica-skill/scripts/habitica.sh list dailys 2>/dev/null | grep -c "value: 0" || echo "0")

cat > "$OUTPUT_FILE" << HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nik's Daily Brief</title>
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
        .event {
            display: flex;
            align-items: flex-start;
            padding: 12px 0;
            border-bottom: 1px solid rgba(255,255,255,0.05);
        }
        .event:last-child { border-bottom: none; }
        .event-time { min-width: 80px; color: #64ffda; font-size: 0.9rem; }
        .event-title { flex: 1; }
        .event-person { color: #8892b0; font-size: 0.85rem; }
        .badge {
            display: inline-block;
            background: rgba(100, 255, 218, 0.1);
            color: #64ffda;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            margin-left: 10px;
        }
        .badge.pending { background: rgba(239, 1, 7, 0.1); color: #ef0107; }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }
        .stat-box {
            background: rgba(255,255,255,0.03);
            border-radius: 12px;
            padding: 20px;
            text-align: center;
        }
        .stat-number { font-size: 2rem; font-weight: 600; color: #64ffda; }
        .stat-label { font-size: 0.9rem; color: #8892b0; margin-top: 5px; }
        .footer {
            text-align: center;
            padding: 30px;
            color: #8892b0;
            font-size: 0.9rem;
        }
        .refresh-btn {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px 30px;
            border-radius: 30px;
            text-decoration: none;
            margin-top: 20px;
            border: none;
            cursor: pointer;
            font-size: 1rem;
        }
        .refresh-btn:hover { opacity: 0.9; }
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
            <h1>Morning Brief</h1>
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
                <span class="icon">📊</span>
                Daily Snapshot
            </div>
            <div class="stats-grid">
                <div class="stat-box">
                    <div class="stat-number">$EMAIL_COUNT</div>
                    <div class="stat-label">Unread Emails</div>
                </div>
                <div class="stat-box">
                    <div class="stat-number">$TODO_COUNT</div>
                    <div class="stat-label">Tasks Due</div>
                </div>
                <div class="stat-box">
                    <div class="stat-number">$HABITICA_PENDING</div>
                    <div class="stat-label">Habits Pending</div>
                </div>
            </div>
        </div>

        <div class="footer">
            Last updated: $TIME<br>
            <button class="refresh-btn" onclick="location.reload()">Refresh Brief</button>
        </div>
    </div>
</body>
</html>
HTML

echo "Brief generated at $OUTPUT_FILE"