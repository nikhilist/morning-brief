#!/usr/bin/env python3
import json
import sys
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

ny = ZoneInfo('America/New_York')


def parse_dt(value):
    if not value:
        return None
    value = str(value).strip()
    fmts = [
        '%Y-%m-%dT%H:%M:%S.%fZ',
        '%Y-%m-%dT%H:%M:%SZ',
        '%Y-%m-%d %H:%M',
        '%Y-%m-%dT%H:%M:%S%z',
        '%Y-%m-%dT%H:%M:%S.%f%z',
    ]
    for fmt in fmts:
        try:
            dt = datetime.strptime(value, fmt)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=ny)
            return dt.astimezone(ny)
        except Exception:
            pass
    try:
        if value.endswith('Z'):
            value = value.replace('Z', '+00:00')
        dt = datetime.fromisoformat(value)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=ny)
        return dt.astimezone(ny)
    except Exception:
        return None


def age_string(then, now):
    if then is None:
        return 'age unknown'
    delta = now - then
    mins = int(delta.total_seconds() // 60)
    if mins < 60:
        return f'{max(mins,0)}m ago'
    hours = mins // 60
    if hours < 24:
        return f'{hours}h ago'
    days = hours // 24
    return f'{days}d ago'


payload = json.load(sys.stdin)
now = parse_dt(payload.get('generated_at')) or datetime.now(ny)

out = {
    'generated_at_local': now.strftime('%Y-%m-%d %I:%M %p %Z'),
    'weather_fetched_age': age_string(parse_dt(payload.get('weather_fetched_at')), now),
    'market_fetched_age': age_string(parse_dt(payload.get('market_fetched_at')), now),
    'arsenal_fetched_age': age_string(parse_dt(payload.get('arsenal_fetched_at')), now),
    'latest_email_age': age_string(parse_dt(payload.get('latest_email_at')), now),
    'latest_inbox_task_age': age_string(parse_dt(payload.get('latest_inbox_task_at')), now),
}

print(json.dumps(out))
