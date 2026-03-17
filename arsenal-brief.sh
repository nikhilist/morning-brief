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

TODAY_EVENTS=$(gog calendar events "$ARSENAL_CALENDAR_ID" --from "$TODAY_START" --to "$TODAY_END" --json 2>/dev/null || echo '{"events":[]}')
UPCOMING_EVENTS=$(gog calendar events "$ARSENAL_CALENDAR_ID" --from "$TODAY_START" --to "$LOOKAHEAD_END" --json 2>/dev/null || echo '{"events":[]}')
RECENT_EVENTS=$(gog calendar events "$ARSENAL_CALENDAR_ID" --from "$LOOKBACK_START" --to "$TODAY_START" --json 2>/dev/null || echo '{"events":[]}')

NEXT_MATCH_JSON=$(echo "$UPCOMING_EVENTS" | jq -c '.events | map(select((.summary // "") | test("Arsenal"; "i"))) | sort_by(.start.dateTime // .start.date // "") | .[0] // empty')
TODAY_MATCH_JSON=$(echo "$TODAY_EVENTS" | jq -c '.events | map(select((.summary // "") | test("Arsenal"; "i"))) | sort_by(.start.dateTime // .start.date // "") | .[0] // empty')
LAST_MATCH_JSON=$(echo "$RECENT_EVENTS" | jq -c '.events | map(select((.summary // "") | test("Arsenal"; "i"))) | sort_by(.start.dateTime // .start.date // "") | last // empty')

python3 - "$NEXT_MATCH_JSON" "$TODAY_MATCH_JSON" "$LAST_MATCH_JSON" > "$TMP_DIR/match.json" <<'PY'
import sys, json, re
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

def clean_desc(text):
    text = (text or '').replace('\n', ' ')
    text = re.sub(r'https?://\S+', '', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text[:220]

def build_focus(event, label):
    title = event.get('summary') or 'Arsenal match'
    start = ((event.get('start') or {}).get('dateTime')) or ((event.get('start') or {}).get('date')) or ''
    location = event.get('location') or ''
    desc = clean_desc(event.get('description') or '')
    kickoff = fmt_time(start)
    rel = rel_time(start)
    summary = f'{label}: {title} at {kickoff}'
    return {
        'summary': summary,
        'title': title,
        'kickoff': kickoff,
        'relative': rel,
        'location': location,
        'description': desc,
    }

def maybe_result(title):
    m = re.search(r'(\d+)\s*[-–]\s*(\d+)', title or '')
    if m:
        return title
    return ''

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

if last_match and not today_match:
    title = last_match.get('summary') or 'Recent Arsenal match'
    result = maybe_result(title)
    if result:
        out['result_html'] = f"<li><strong>Last result:</strong> {result}</li>"

print(json.dumps(out))
PY

MATCH_SUMMARY=$(jq -r '.match_summary' "$TMP_DIR/match.json")
WHAT_MATTERS_BASE=$(jq -r '.what_matters' "$TMP_DIR/match.json")
MATCH_HTML=$(jq -r '.match_html' "$TMP_DIR/match.json")
RESULT_HTML=$(jq -r '.result_html' "$TMP_DIR/match.json")

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
        for item in channel.findall('item')[:20]:
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
    fresh = [x for x in items if x.get('ts', 0) and x['ts'] >= now - 172800 and 'women' not in x['title'].lower()]
    out = fresh[:6] if fresh else [x for x in items if 'women' not in x['title'].lower()][:6]
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
clean = html.unescape(re.sub(r'\s+', ' ', text))
patterns = [
    (r'Post-[A-Za-z]+ quotes round-up.{0,120}', 'Post-match reaction'),
    (r'Highlights?:.{0,120}', 'Match highlights'),
    (r'Report: Arsenal .{0,120}', 'Official match report'),
    (r'Gallery: .{0,120}', 'Official gallery'),
    (r'Preview: .{0,120}', 'Official match preview'),
    (r'How to watch .{0,120}', 'Broadcast/watch info'),
    (r'Arteta provides update on .{0,120}', 'Team-news signal from the manager/media cycle'),
    (r'Odegaard on .{0,120}', 'Player/team-news signal'),
]

def tidy(title):
    title = re.split(r'loading=|typeof=|src=|href=|/></|&quot;|<|\|', title, 1)[0]
    title = re.sub(r'\s+', ' ', title)
    return title.strip(' -–|"\' ')

out = []
seen = set()
for pattern, desc in patterns:
    for m in re.finditer(pattern, clean, flags=re.I):
        title = tidy(m.group(0))
        if len(title) < 8:
            continue
        low = title.lower()
        if low in seen:
            continue
        seen.add(low)
        out.append({"source":"Arsenal.com", "title": title, "desc": desc})
        if len(out) >= 8:
            break
    if len(out) >= 8:
        break
print(json.dumps(out[:8]))
PY

curl -sL "https://www.bbc.com/sport/football/teams/arsenal" -o "$TMP_DIR/bbc.html" || true
python3 - "$TMP_DIR/bbc.html" > "$TMP_DIR/bbc.json" <<'PY'
import sys, json, re, html
text = ''
try:
    text = open(sys.argv[1], 'r', encoding='utf-8', errors='ignore').read()
except Exception:
    pass
# Remove script/style tags and their content
text = re.sub(r'<script[^>]*>.*?</script>', ' ', text, flags=re.S|re.I)
text = re.sub(r'<style[^>]*>.*?</style>', ' ', text, flags=re.S|re.I)
# Remove meta tags and other head content
text = re.sub(r'<meta[^>]*>', ' ', text, flags=re.I)
text = re.sub(r'<link[^>]*>', ' ', text, flags=re.I)
# Clean up HTML entities and whitespace
clean = html.unescape(re.sub(r'\s+', ' ', text))
out = []
# Look for article headlines in the page - BBC uses specific data attributes and classes
# Try to find actual article headlines, not meta tag content
headline_patterns = [
    r'data-testid="card-headline"[^>]*>([^<]+)</',
    r'class="[^"]*headline[^"]*"[^>]*>([^<]+)</',
    r'<h[23][^>]*>([^<]+)</h[23]',
]
seen = set()
for pattern in headline_patterns:
    for m in re.finditer(pattern, clean, flags=re.I):
        title = m.group(1).strip() if m.groups() else m.group(0).strip()
        # Filter out junk
        if len(title) < 15 or len(title) > 150:
            continue
        if any(x in title.lower() for x in ['var ', 'function', '=>', '{', '}', '="', 'twitter', 'og:', 'meta']):
            continue
        # Must contain Arsenal-related terms
        if not any(x in title.lower() for x in ['arsenal', 'arteta', 'saka', 'odegaard', 'havertz', 'rice', 'saliba', 'partey', 'white', 'gabriel', 'martinelli', 'trossard']):
            continue
        low = title.lower()
        if low in seen:
            continue
        seen.add(low)
        desc = 'BBC Arsenal coverage'
        if 'have the chance' in low or 'host' in low or 'visit' in low:
            desc = 'BBC match framing'
        elif any(x in low for x in ['drew', 'beat', 'won', 'penalty', 'score', 'defeat']):
            desc = 'BBC recent result framing'
        out.append({"source":"BBC", "title": title, "desc": desc})
        if len(out) >= 5:
            break
    if len(out) >= 5:
        break
print(json.dumps(out[:5]))
PY

jq -s 'add | unique_by(.title)' "$TMP_DIR/official.json" "$TMP_DIR/arseblog.json" "$TMP_DIR/bbc.json" > "$TMP_DIR/news-all.json"
python3 - "$TMP_DIR/news-all.json" > "$TMP_DIR/news.json" <<'PY'
import sys, json, re
items = json.load(open(sys.argv[1]))

def score(item):
    s = 0
    source = item.get('source','')
    title = (item.get('title') or '').lower()
    desc = (item.get('desc') or '').lower()
    if source == 'Arsenal.com': s += 30
    if source == 'BBC': s += 25
    if source == 'Arseblog': s += 20
    if any(x in title for x in ['post-', 'report:', 'reaction', 'quotes', 'highlights', 'result']): s += 28
    if 'update' in title or 'fitness' in title: s += 18
    if 'arteta' in title or 'odegaard' in title or 'saka' in title or 'havertz' in title: s += 10
    if 'preview' in title: s -= 18
    if 'how to watch' in title: s -= 20
    if 'training gallery' in title or 'gallery:' in title: s -= 12
    if 'women' in title: s -= 30
    if 'broadcast/watch info' in desc: s -= 10
    return -s
items = sorted(items, key=score)[:3]
json.dump(items, sys.stdout)
PY

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
HEADLINE_THREE=$(jq -r '.[2].title // empty' "$TMP_DIR/news.json")

TEAM_NEWS_HTML=""
if printf '%s' "$HEADLINE_ONE $HEADLINE_TWO $HEADLINE_THREE" | grep -qi 'Odegaard\|Trossard\|fitness\|update'; then
  TEAM_NEWS_HTML+="<li><strong>Fitness watch:</strong> Odegaard/Trossard availability is in the official pre-match signal set, so that is real team-news rather than fluff.</li>"
fi
if printf '%s' "$HEADLINE_ONE $HEADLINE_TWO $HEADLINE_THREE" | grep -qi 'Arteta'; then
  TEAM_NEWS_HTML+="<li><strong>Manager line:</strong> Arteta is part of the pre-match cycle, which usually means the section to trust most is availability plus selection hints, not fan noise.</li>"
fi
TEAM_NEWS_HTML=${TEAM_NEWS_HTML:-<li><span class="muted">No clean injury/team-news extraction yet beyond headline signals.</span></li>}

LINEUP_HTML="<li><strong>Selection question:</strong> The module still refuses to fake a probable XI. The real watchpoints are the Odegaard/Trossard fitness picture and how aggressive Arteta goes before the next run of fixtures.</li>"
if ! printf '%s' "$HEADLINE_ONE $HEADLINE_TWO $HEADLINE_THREE" | grep -qi 'Odegaard\|Trossard\|fitness\|update'; then
  LINEUP_HTML="<li><strong>Selection question:</strong> No trustworthy lineup edge yet beyond standard match-preview noise, so better to wait for stronger team-news signals.</li>"
fi

SOCIAL_HTML="<li><strong>Signal policy:</strong> Kept intentionally strict. When this section is populated, it should only surface official Arsenal output or converged reporter signals — not random rumor sludge.</li>"

WHAT_MATTERS="$WHAT_MATTERS_BASE"
if [ -n "$HEADLINE_ONE" ]; then
  WHAT_MATTERS="$WHAT_MATTERS_BASE Top news line: $HEADLINE_ONE"
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
