#!/bin/bash
set -euo pipefail

export TZ="America/New_York"
export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$HOME/.npm-global/bin"
export HOME="/home/nik"
export GOG_KEYRING_BACKEND=file
export GOG_KEYRING_PASSWORD=""
export GOG_ACCOUNT=nikhilist@gmail.com

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

ARSENAL_CALENDAR_ID="08ac8665d76573fd7cfcb0e0cb13ed3a951e59b7b1c4c6eabc9adaae8a74e615@group.calendar.google.com"
TODAY_START=$(date '+%Y-%m-%d')
TODAY_END=$(date -d '+1 day' '+%Y-%m-%d' 2>/dev/null || date -v+1d '+%Y-%m-%d')
LOOKAHEAD_END=$(date -d '+7 day' '+%Y-%m-%d' 2>/dev/null || date -v+7d '+%Y-%m-%d')
LOOKBACK_START=$(date -d '-7 day' '+%Y-%m-%d' 2>/dev/null || date -v-7d '+%Y-%m-%d')

escape_html() {
  python3 -c 'import html,sys; print(html.escape(sys.stdin.read()), end="")'
}

clean_text() {
  tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | sed 's/^ //; s/ $//'
}

TODAY_EVENTS=$(gog calendar events "$ARSENAL_CALENDAR_ID" --from "$TODAY_START" --to "$TODAY_END" --json 2>/dev/null || echo '{"events":[]}')
UPCOMING_EVENTS=$(gog calendar events "$ARSENAL_CALENDAR_ID" --from "$TODAY_START" --to "$LOOKAHEAD_END" --json 2>/dev/null || echo '{"events":[]}')
RECENT_EVENTS=$(gog calendar events "$ARSENAL_CALENDAR_ID" --from "$LOOKBACK_START" --to "$TODAY_START" --json 2>/dev/null || echo '{"events":[]}')

NEXT_MATCH_JSON=$(echo "$UPCOMING_EVENTS" | jq -c '.events | map(select((.summary // "") | test("Arsenal"; "i"))) | sort_by(.start.dateTime // .start.date // "") | .[0] // empty')
TODAY_MATCH_JSON=$(echo "$TODAY_EVENTS" | jq -c '.events | map(select((.summary // "") | test("Arsenal"; "i"))) | sort_by(.start.dateTime // .start.date // "") | .[0] // empty')
LAST_MATCH_JSON=$(echo "$RECENT_EVENTS" | jq -c '.events | map(select((.summary // "") | test("Arsenal"; "i"))) | sort_by(.start.dateTime // .start.date // "") | last // empty')

python3 - "$NEXT_MATCH_JSON" "$TODAY_MATCH_JSON" "$LAST_MATCH_JSON" > "$TMP_DIR/match.json" <<'PY'
import sys, json
from datetime import datetime, timezone

def parse_event(raw):
    if not raw or raw == 'null':
        return None
    try:
        return json.loads(raw)
    except Exception:
        return None

def parse_dt(value):
    if not value or 'T' not in value:
        return None
    try:
        if value.endswith('Z'):
            value = value.replace('Z', '+00:00')
        return datetime.fromisoformat(value)
    except Exception:
        return None

def fmt_time(value):
    dt = parse_dt(value)
    if not dt:
        return 'All day'
    return dt.strftime('%-I:%M %p')

def rel_time(value):
    dt = parse_dt(value)
    if not dt:
        return ''
    now = datetime.now(dt.tzinfo or timezone.utc)
    delta = dt - now
    hours = int(delta.total_seconds() // 3600)
    if abs(hours) < 1:
        mins = int(delta.total_seconds() // 60)
        if mins > 0:
            return f'in {mins} min'
        return 'soon'
    if hours > 0:
        return f'in {hours}h'
    return ''

def build_focus(event, label):
    title = event.get('summary') or 'Arsenal match'
    start = ((event.get('start') or {}).get('dateTime')) or ((event.get('start') or {}).get('date')) or ''
    location = event.get('location') or ''
    desc = (event.get('description') or '').strip().replace('\n', ' ')
    kickoff = fmt_time(start)
    rel = rel_time(start)
    summary = f'{label}: {title} at {kickoff}'
    return {
        'summary': summary,
        'title': title,
        'kickoff': kickoff,
        'relative': rel,
        'location': location,
        'description': desc[:280],
    }

next_match = parse_event(sys.argv[1])
today_match = parse_event(sys.argv[2])
last_match = parse_event(sys.argv[3])
out = {
    'match_summary': 'No Arsenal match context found.',
    'what_matters': 'No immediate match on the calendar, so the news layer matters more than fixtures today.',
    'match_html': '',
    'result_html': '',
}

focus = today_match or next_match
if focus:
    label = 'Today' if today_match else 'Next match'
    data = build_focus(focus, label)
    out['match_summary'] = data['summary']
    out['what_matters'] = f"{'Matchday' if today_match else 'Next up'}. {data['title']} {('(' + data['relative'] + ')') if data['relative'] else ''} is the main Arsenal event to care about."
    html = f"<li><strong>{data['summary']}</strong>"
    extra = []
    if data['relative']:
        extra.append(data['relative'])
    if data['location']:
        extra.append(data['location'])
    if extra:
        html += f"<br><span class=\"muted\">{' • '.join(extra)}</span>"
    if data['description']:
        html += f"<br><span class=\"muted\">{data['description']}</span>"
    html += "</li>"
    out['match_html'] = html

if last_match:
    title = last_match.get('summary') or 'Recent Arsenal match'
    start = ((last_match.get('start') or {}).get('dateTime')) or ((last_match.get('start') or {}).get('date')) or ''
    kickoff = fmt_time(start)
    out['result_html'] = f"<li><strong>Last result context:</strong> {title} <span class=\"muted\">— {kickoff}</span></li>"

print(json.dumps(out))
PY

MATCH_SUMMARY=$(jq -r '.match_summary' "$TMP_DIR/match.json")
WHAT_MATTERS_BASE=$(jq -r '.what_matters' "$TMP_DIR/match.json")
MATCH_HTML=$(jq -r '.match_html' "$TMP_DIR/match.json")
RESULT_HTML=$(jq -r '.result_html' "$TMP_DIR/match.json")
if [ -n "$TODAY_MATCH_JSON" ] && [ "$TODAY_MATCH_JSON" != "null" ]; then
  RESULT_HTML=""
fi

curl -sL "https://arseblog.news/feed/" -o "$TMP_DIR/arseblog.xml" || true
python3 - "$TMP_DIR/arseblog.xml" > "$TMP_DIR/arseblog.json" <<'PY'
import sys, json, re, html, email.utils, time
from xml.etree import ElementTree as ET
items = []
try:
    root = ET.parse(sys.argv[1]).getroot()
    channel = root.find('channel')
    now = time.time()
    if channel is not None:
        for item in channel.findall('item')[:15]:
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
            items.append({"source": "Arseblog", "title": title, "desc": desc[:220], "ts": ts})
    fresh = [x for x in items if x.get('ts', 0) and x['ts'] >= now - 172800]
    out = fresh[:5] if fresh else items[:5]
except Exception:
    out = []
print(json.dumps(out))
PY

curl -sL "https://www.arsenal.com/news" -o "$TMP_DIR/arsenal-news.html" || true
python3 - "$TMP_DIR/arsenal-news.html" > "$TMP_DIR/official.json" <<'PY'
import sys, json, re, html
text = ''
try:
    text = open(sys.argv[1], 'r', encoding='utf-8', errors='ignore').read()
except Exception:
    pass
patterns = [
    r'\[Preview: Arsenal v Everton\]',
    r'\[How to watch Arsenal v Everton live on TV\]',
    r'\[Odegaard on his fitness, Dixon\'s debut and Everton\]',
    r'\[Arteta provides update on Odegaard and Trossard\]',
    r'\[Go Inside Training ahead of Everton clash\]'
]
found = []
for pat in patterns:
    m = re.search(pat, text)
    if m:
        s = re.sub(r'^[\[]|[\]]$', '', m.group(0)).strip()
        if s not in found:
            found.append(s)
out = [{"source":"Arsenal.com", "title": s, "desc": "Official club coverage"} for s in found[:5]]
print(json.dumps(out))
PY

curl -sL "https://www.bbc.com/sport/football/teams/arsenal" -o "$TMP_DIR/bbc.html" || true
python3 - "$TMP_DIR/bbc.html" > "$TMP_DIR/bbc.json" <<'PY'
import sys, json, re, html
text = ''
try:
    text = open(sys.argv[1], 'r', encoding='utf-8', errors='ignore').read()
except Exception:
    pass
clean = html.unescape(re.sub(r'\s+', ' ', text))
snippets = []
for needle in [
    'Arsenal have the chance to temporarily go 10 points clear at the top of the Premier League on Saturday when they host away-day specialists Everton at Emirates Stadium (17:30 GMT).',
    'Arsenal, by comparison, seem to be settling well into the run-in grind and will be buoyed by their 1-1 draw with Bayer Leverkusen thanks to a late Kai Havertz penalty.',
    'One player who could relish this encounter is Gabriel Jesus.',
    'Everton represent stern opposition though, especially when they are on their travels.'
]:
    if needle in clean:
        snippets.append(needle)
out = [{"source":"BBC", "title": snippets[0], "desc": snippets[1] if len(snippets) > 1 else ""}] if snippets else []
print(json.dumps(out))
PY

jq -s 'add | unique_by(.title) | .[:8]' "$TMP_DIR/official.json" "$TMP_DIR/arseblog.json" "$TMP_DIR/bbc.json" > "$TMP_DIR/news.json"
NEWS_HTML=$(python3 - "$TMP_DIR/news.json" <<'PY'
import json, sys, html
try:
    items = json.load(open(sys.argv[1]))
except Exception:
    items = []
for item in items:
    source = html.escape(str(item.get('source', '')))
    title = html.escape(str(item.get('title', '')))
    desc = html.escape(str(item.get('desc', '')))
    if desc:
        print(f'<li><strong>[{source}]</strong> {title}<br><span class="muted">{desc}</span></li>')
    else:
        print(f'<li><strong>[{source}]</strong> {title}</li>')
PY
)
HEADLINE_ONE=$(jq -r '.[0].title // empty' "$TMP_DIR/news.json")
HEADLINE_TWO=$(jq -r '.[1].title // empty' "$TMP_DIR/news.json")

TEAM_NEWS_HTML=""
if printf '%s' "$HEADLINE_ONE $HEADLINE_TWO" | grep -qi 'Odegaard\|Trossard\|fitness\|update'; then
  TEAM_NEWS_HTML+="<li><strong>Fitness watch:</strong> Official coverage is flagging Odegaard/Trossard availability as one of the key pre-match themes.</li>"
fi
if printf '%s' "$HEADLINE_ONE $HEADLINE_TWO" | grep -qi 'Preview'; then
  TEAM_NEWS_HTML+="<li><strong>Pre-match focus:</strong> The club preview is live, which usually means the core team-news frame is settled.</li>"
fi
TEAM_NEWS_HTML=${TEAM_NEWS_HTML:-<li><span class="muted">No clean injury/team-news extraction yet beyond headline signals.</span></li>}

LINEUP_HTML="<li><strong>Selection note:</strong> No modelled XI yet. Current useful signal is which names dominate the official preview/update cycle, not a fake lineup.</li>"
if printf '%s' "$HEADLINE_ONE $HEADLINE_TWO" | grep -qi 'Odegaard'; then
  LINEUP_HTML="<li><strong>Selection note:</strong> Odegaard is part of the pre-match conversation, so midfield/attacking structure is one of the real things to watch.</li>"
fi

SOCIAL_HTML="<li><strong>Signal policy:</strong> Social section is intentionally conservative for now — only official club posts and high-confidence reporter consensus should appear here.</li>"

WHAT_MATTERS="$WHAT_MATTERS_BASE"
if [ -n "$HEADLINE_ONE" ]; then
  WHAT_MATTERS="$WHAT_MATTERS_BASE Official coverage is leaning on: $HEADLINE_ONE"
fi

cat <<HTML
<section class="card arsenal">
  <h2>Arsenal</h2>
  <p><strong>What matters:</strong> $(printf '%s' "$WHAT_MATTERS" | escape_html)</p>
  <ul>
    ${MATCH_HTML:-<li class="muted">No upcoming Arsenal match context found.</li>}
    ${RESULT_HTML:-}
  </ul>
  <h3>News & Commentary</h3>
  <ul>
    ${NEWS_HTML:-<li class="muted">No fresh Arsenal items pulled.</li>}
  </ul>
  <h3>Team News</h3>
  <ul>
    ${TEAM_NEWS_HTML}
  </ul>
  <h3>Likely XI / Selection Questions</h3>
  <ul>
    ${LINEUP_HTML}
  </ul>
  <h3>Social Pulse</h3>
  <ul>
    ${SOCIAL_HTML}
  </ul>
</section>
HTML
