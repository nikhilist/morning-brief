#!/usr/bin/env python3
import json
import re
import sys
from html import unescape


def strip_html(text: str) -> str:
    text = text or ''
    text = re.sub(r'<br\s*/?>', '\n', text, flags=re.I)
    text = re.sub(r'</li>', '\n', text, flags=re.I)
    text = re.sub(r'</p>', '\n', text, flags=re.I)
    text = re.sub(r'<[^>]+>', ' ', text)
    text = unescape(text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def extract_lines_from_li(html_text: str):
    items = re.findall(r'<li[^>]*>(.*?)</li>', html_text or '', flags=re.I | re.S)
    cleaned = []
    for item in items:
        text = strip_html(item)
        if text:
            cleaned.append(text)
    return cleaned


def first_match(pattern, text, default=''):
    m = re.search(pattern, text or '', flags=re.I | re.S)
    return m.group(1).strip() if m else default


def infer_signal_noise(raw, result):
    signal = []
    noise = []
    blind_spots = []
    latent_risks = []

    todo_count = int(raw.get('todo_count') or 0)
    inbox_unscheduled = int(raw.get('inbox_unscheduled_count') or 0)
    email_new_count = int(raw.get('email_new_count') or 0)
    habit_count = int(raw.get('habit_count') or 0)

    task_items = result['tasks']['items']
    email_items = result['email']['needs_attention']
    weather_summary = raw.get('weather_summary') or ''
    trip_summary = raw.get('trip_logistics_summary') or ''
    upcoming = result['calendar']['upcoming_focus_days']
    today_events = result['calendar']['today_events']

    if task_items:
        signal.append(f"Open task pressure is real: {task_items[0]}")
    if upcoming:
        signal.append(f"Upcoming planning edge: {upcoming[0]}")
    if email_items and email_new_count > 0:
        signal.append(f"Fresh inbox signal exists: {email_items[0]}")
    if 'weather:' in weather_summary.lower() or 'home weather' in weather_summary.lower():
        signal.append(weather_summary)

    if email_new_count == 0:
        noise.append('No new unread email signal right now.')
    if 'Nothing weather-wise should get in your way.' in weather_summary:
        noise.append('Weather is not a planning issue.')
    if 'No current trip logistics detected.' in trip_summary or 'No recent trip logistics found.' in trip_summary:
        noise.append('No active trip-logistics action is supported by the current evidence.')
    if today_events:
        noise.append('Completed or already-lived events should not dominate the brief unless they change tomorrow.')

    if inbox_unscheduled >= 3:
        blind_spots.append('Unscheduled inbox tasks can hide low-grade obligations that never earn real time.')
    if todo_count > 0 and habit_count >= 3:
        blind_spots.append('When admin tasks and basic maintenance both stay open, the issue is usually activation energy, not capacity.')
    if email_new_count == 0 and todo_count > 0:
        blind_spots.append('The inbox is not the blocker right now; execution is.')

    if task_items and any('soccer' in x.lower() for x in task_items):
        latent_risks.append('Child logistics are drifting because enrollment has already missed its original timing.')
    if upcoming:
        latent_risks.append('A future family planning day exists; if ignored now, it will convert into short-notice friction later.')
    if habit_count >= 3:
        latent_risks.append('Repeatedly open basics are a weak-systems signal, not a one-day anomaly.')

    return {
        'signal': signal[:5],
        'noise': noise[:5],
        'blind_spots': blind_spots[:5],
        'latent_risks': latent_risks[:5],
    }


def main():
    raw = json.load(sys.stdin)

    result = {
        'generated_at': raw.get('generated_at'),
        'weather_fetched_at': raw.get('weather_fetched_at'),
        'market_fetched_at': raw.get('market_fetched_at'),
        'arsenal_fetched_at': raw.get('arsenal_fetched_at'),
        'latest_email_at': raw.get('latest_email_at'),
        'latest_inbox_task_at': raw.get('latest_inbox_task_at'),
        'brief_type': raw.get('brief_type'),
        'brief_mode': raw.get('brief_mode'),
        'calendar': {
            'day_shape': raw.get('day_shape'),
            'tomorrow_shape': raw.get('tomorrow_shape'),
            'today_events': extract_lines_from_li((raw.get('calendar_html') or '').replace('<div class="event">', '<li>').replace('</div><div class="event-title">', ' ').replace('</div></div>', '</li>')),
            'upcoming_focus_days': extract_lines_from_li(raw.get('upcoming_html') or ''),
        },
        'tasks': {
            'summary': raw.get('task_summary'),
            'count': raw.get('todo_count'),
            'inbox_unscheduled_count': raw.get('inbox_unscheduled_count'),
            'items': extract_lines_from_li(raw.get('tasks_html') or ''),
        },
        'trip': {
            'summary': raw.get('trip_logistics_summary'),
            'next_action': raw.get('trip_next_action'),
            'help_ideas': [x.strip() for x in (raw.get('trip_help_ideas') or '').split('|') if x.strip()],
            'items': extract_lines_from_li(raw.get('trip_html') or ''),
        },
        'email': {
            'summary': raw.get('email_summary'),
            'new_count': raw.get('email_new_count'),
            'needs_attention': extract_lines_from_li(raw.get('email_html') or ''),
        },
        'weather': {
            'summary': raw.get('weather_summary'),
            'details': extract_lines_from_li(raw.get('weather_html') or ''),
        },
        'habits': {
            'summary': raw.get('habit_summary'),
            'count': raw.get('habit_count'),
            'open_items': extract_lines_from_li(raw.get('habits_html') or ''),
        },
        'arsenal': {
            'what_matters': first_match(r'<strong>What matters:</strong>\s*(.*?)</p>', raw.get('arsenal_html') or ''),
            'items': extract_lines_from_li(raw.get('arsenal_html') or ''),
        },
        'markets': {
            'summary': raw.get('market_summary'),
            'items': extract_lines_from_li(raw.get('market_html') or ''),
        },
        'fallback': raw.get('fallback', {}),
    }

    result['decision_support'] = infer_signal_noise(raw, result)
    print(json.dumps(result))


if __name__ == '__main__':
    main()
