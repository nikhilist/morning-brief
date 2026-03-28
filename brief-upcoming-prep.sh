#!/bin/bash
set -euo pipefail
export TZ="America/New_York"
export GOG_KEYRING_BACKEND=file
export GOG_KEYRING_PASSWORD=""
export GOG_ACCOUNT=nikhilist@gmail.com

python3 - <<'PY'
import subprocess, json, html, re
from datetime import datetime, timedelta

TZ = 'America/New_York'
now = datetime.now()
start = now.strftime('%Y-%m-%d')
end = (now + timedelta(days=7)).strftime('%Y-%m-%d')
cal_ids = [
    'nikhilist@gmail.com',
    '8tdo49s92dr6h34pcros8a17k8@group.calendar.google.com',
    '08ac8665d76573fd7cfcb0e0cb13ed3a951e59b7b1c4c6eabc9adaae8a74e615@group.calendar.google.com',
]

def esc(s):
    return html.escape(str(s))

def run_events(cal_id):
    try:
        out = subprocess.check_output([
            'gog', 'calendar', 'events', cal_id, '--from', start, '--to', end, '--json'
        ], text=True)
        return json.loads(out).get('events', [])
    except Exception:
        return []

def parse_event_day(ev):
    s = ev.get('start', {})
    if 'dateTime' in s:
        return s['dateTime'][:10]
    return s.get('date', '')

def parse_event_time(ev):
    s = ev.get('start', {})
    if 'dateTime' in s:
        dt = s['dateTime']
        try:
            from zoneinfo import ZoneInfo
            parsed = datetime.fromisoformat(dt.replace('Z', '+00:00'))
            local = parsed.astimezone(ZoneInfo('America/New_York'))
            return local.strftime('%-I:%M %p')
        except Exception:
            try:
                t = dt.split('T')[1][:5]
                hh, mm = t.split(':')
                hh = int(hh)
                suffix = 'AM' if hh < 12 else 'PM'
                hh12 = hh % 12 or 12
                return f'{hh12}:{mm} {suffix}'
            except Exception:
                return 'Timed'
    return 'All day'

def score_event(ev):
    title = (ev.get('summary') or '').lower()
    score = 0
    reasons = []

    travelish = any(k in title for k in ['travel', 'flight', 'trip'])
    looks_like_return = any(k in title for k in ['return', 'mco', 'to newark', 'to ewr', 'to nj', 'to princeton'])
    looks_like_outbound = any(k in title for k in ['to orlando', 'to florida', 'ewr → mco', 'newark to orlando'])

    if travelish:
        if looks_like_return and not looks_like_outbound:
            score += 1
            reasons.append('travel marker only')
        else:
            score += 5
            reasons.append('travel logistics')
    if any(k in title for k in ['parent', 'school', 'doctor', 'dentist', 'appointment']):
        score += 4; reasons.append('needs daytime planning')
    if any(k in title for k in ['birthday', 'anniversary']):
        score += 2; reasons.append('easy to forget if not decided early')
    if any(k in title for k in ['arsenal']):
        score += 2; reasons.append('you care enough that timing matters')
    if any(k in title for k in ['karate', 'storytime', 'dinner']):
        score += 2; reasons.append('family timing block')
    return score, reasons

all_events = []
for cal in cal_ids:
    all_events.extend(run_events(cal))

by_day = {}
for ev in all_events:
    day = parse_event_day(ev)
    by_day.setdefault(day, []).append(ev)

prep_items = []
today = now.date().isoformat()

for day, events in sorted(by_day.items()):
    if not day or day < today:
        continue
    day_score = 0
    notes = []
    labels = []
    for ev in events:
        s, reasons = score_event(ev)
        if s > 0:
            day_score += s
            labels.append(f"{parse_event_time(ev)} — {ev.get('summary','Untitled')}")
            notes.extend(reasons)
    if len(events) >= 3:
        day_score += 2
        notes.append('calendar density')

    joined_titles = ' '.join((ev.get('summary') or '').lower() for ev in events)
    if ('flight' in joined_titles or 'travel' in joined_titles or 'trip' in joined_titles) and not any(n == 'travel logistics' for n in notes):
        day_score = min(day_score, 3)

    if day_score >= 4:
        uniq_notes = []
        for n in notes:
            if n not in uniq_notes:
                uniq_notes.append(n)
        prep_items.append({
            'day': day,
            'score': day_score,
            'labels': labels[:4],
            'notes': uniq_notes[:3],
        })

summary = 'Nothing in the next week really needs early prep.'
if prep_items:
    summary = f"{prep_items[0]['day']} is the first day that looks worth thinking about ahead of time."

print('<section class="card">')
print('<h2>Upcoming Things Worth Thinking About</h2>')
print('<p><strong>What matters:</strong> ' + esc(summary) + '</p>')
print('<ul>')
if prep_items:
    for item in prep_items[:4]:
        note = '; '.join(item['notes'])
        labels = ' • '.join(item['labels'])
        print(f"<li><strong>{esc(item['day'])}</strong> — {esc(note)}<br><span class=\"muted\">{esc(labels)}</span></li>")
else:
    print('<li class="muted">Nothing upcoming crosses the bar for real prep yet.</li>')
print('</ul>')
print('</section>')
print('__SUMMARY__' + summary)
PY
