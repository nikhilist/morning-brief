#!/bin/bash
set -euo pipefail
export TZ="America/New_York"
export GOG_KEYRING_BACKEND=file
export GOG_KEYRING_PASSWORD=""
export GOG_ACCOUNT=nikhilist@gmail.com

WORKSPACE="/home/nik/.openclaw/workspace"
OUT_FILE="$WORKSPACE/travel-context.json"

python3 - <<'PY' > "$OUT_FILE"
import json
import re
import subprocess
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

ny = ZoneInfo('America/New_York')
now = datetime.now(ny)

def run(args):
    try:
        return subprocess.check_output(args, text=True, stderr=subprocess.DEVNULL)
    except Exception:
        return ''

def parse_iso_day(s):
    if not s:
        return None
    try:
        return datetime.fromisoformat(s.replace('Z', '+00:00')).astimezone(ny).date()
    except Exception:
        try:
            return datetime.strptime(s[:10], '%Y-%m-%d').date()
        except Exception:
            return None

def find(pattern, text, flags=re.I|re.S):
    m = re.search(pattern, text or '', flags)
    return m.group(1).strip() if m else ''

def infer_from_calendar():
    start = (now - timedelta(days=2)).date().isoformat()
    end = (now + timedelta(days=10)).date().isoformat()
    cal_ids = [
        'nikhilist@gmail.com',
        '8tdo49s92dr6h34pcros8a17k8@group.calendar.google.com',
        '08ac8665d76573fd7cfcb0e0cb13ed3a951e59b7b1c4c6eabc9adaae8a74e615@group.calendar.google.com',
    ]
    events = []
    for cal in cal_ids:
        raw = run(['gog', 'calendar', 'events', cal, '--from', start, '--to', end, '--json'])
        if not raw:
            continue
        try:
            events.extend(json.loads(raw).get('events', []))
        except Exception:
            pass

    travel = []
    for ev in events:
        summary = (ev.get('summary') or '')
        lower = summary.lower()
        if not any(k in lower for k in ['flight', 'travel', 'trip', 'ewr', 'mco', 'orlando', 'newark']):
            continue
        start_raw = (ev.get('start') or {}).get('dateTime') or (ev.get('start') or {}).get('date')
        day = parse_iso_day(start_raw)
        if not day:
            continue
        travel.append({'summary': summary, 'day': day.isoformat()})

    active = False
    location_name = 'Princeton, NJ'
    lat = 40.3573
    lon = -74.6672
    tz = 'America/New_York'
    note = 'Default home base.'

    joined = ' '.join(t['summary'].lower() for t in travel)
    has_recent_outbound = any(any(k in t['summary'].lower() for k in ['orlando', 'mco', 'ewr → mco', 'newark']) and parse_iso_day(t['day']) and 0 <= (now.date() - parse_iso_day(t['day'])).days <= 7 for t in travel)
    has_future_return = any(any(k in t['summary'].lower() for k in ['to newark', 'to ewr', 'mco']) and parse_iso_day(t['day']) and 0 <= (parse_iso_day(t['day']) - now.date()).days <= 10 for t in travel)

    if has_recent_outbound and has_future_return:
        active = True
        location_name = 'Travel'
        if 'orlando' in joined or 'mco' in joined:
            location_name = 'Orlando, FL'
            lat = 28.5383
            lon = -81.3792
            tz = 'America/New_York'
        note = 'Auto-inferred active travel from recent outbound + future return calendar signals.'

    return {
        'active': active,
        'location_name': location_name,
        'latitude': lat,
        'longitude': lon,
        'timezone': tz,
        'note': note,
        'source': 'auto-calendar',
        'generated_at': now.isoformat(),
    }

ctx = infer_from_calendar()
print(json.dumps(ctx, indent=2))
PY
