#!/usr/bin/env python3
import json
import os
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

    print(json.dumps(result))


if __name__ == '__main__':
    main()
