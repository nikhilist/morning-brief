#!/bin/bash
set -euo pipefail
export TZ="America/New_York"
export GOG_KEYRING_BACKEND=file
export GOG_KEYRING_PASSWORD=""
export GOG_ACCOUNT=nikhilist@gmail.com

python3 - <<'PY'
import subprocess, json, re, html
from datetime import datetime
from zoneinfo import ZoneInfo

QUERY = 'from:donotreply@chasetravel.com newer_than:30d ("trip" OR "travel reservation")'
ny = ZoneInfo('America/New_York')
now = datetime.now(ny)


def run(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.DEVNULL)


def search_ids():
    try:
        out = run('gog', 'gmail', 'search', QUERY, '--max', '10', '--plain')
    except Exception:
        return []
    ids = []
    for line in out.splitlines()[1:]:
        parts = line.split('\t')
        if parts and parts[0].strip():
            ids.append(parts[0].strip())
    return ids


def get_msg(msg_id):
    try:
        return run('gog', 'gmail', 'get', msg_id)
    except Exception:
        return ''


def find(pattern, text, flags=re.I|re.S):
    m = re.search(pattern, text, flags)
    return m.group(1).strip() if m else ''


def parse_trip(raw):
    if not raw:
        return None
    trip_id = find(r'Trip ID:?\s*#?\s*([0-9]{6,})', raw)
    outbound_date = find(r'Depart\s*:\s*([A-Za-z]{3},\s*[A-Za-z]{3}\s*\d{1,2},\s*\d{4})', raw)
    outbound_dep = find(r'Depart\s*:.*?id="departureTime">\s*([0-9: ]+[ap]m)\s*<', raw)
    outbound_arr = find(r'Depart\s*:.*?id="arrivalTime">\s*([0-9: ]+[ap]m)\s*<', raw)
    outbound_num = find(r'Depart\s*:.*?<p class="theme-font-family-bold"[^>]*>(B6\s*\d+)<', raw)
    return_date = find(r'Return\s*:\s*([A-Za-z]{3},\s*[A-Za-z]{3}\s*\d{1,2},\s*\d{4})', raw)
    return_dep = find(r'Return\s*:.*?id="departureTime">\s*([0-9: ]+[ap]m)\s*<', raw)
    return_arr = find(r'Return\s*:.*?id="arrivalTime">\s*([0-9: ]+[ap]m)\s*<', raw)
    return_num = find(r'Return\s*:.*?<p class="theme-font-family-bold"[^>]*>(B6\s*\d+)<', raw)
    airline_conf = find(r'Airline confirmation:\s*([A-Z0-9]+)', raw)
    travelers = re.findall(r'Traveler\s*\d+:</p>.*?<p[^>]*>\s*([^<]+?)\s*</p>', raw, re.I|re.S)
    total_cost = find(r'Trip total</p></td>\s*<td[^>]*><p[^>]*>\s*\$([0-9,]+\.[0-9]{2})', raw)
    points = find(r'Points redeemed</p></td><td[^>]*><p[^>]*>([0-9,]+\s*pts)', raw)
    billed = find(r'Billed to card</p></td><td[^>]*><p[^>]*>\$([0-9,]+\.[0-9]{2})', raw)
    seats_missing = bool(re.search(r'Seats:\s*Not chosen for some travelers|seat assignments are not available', raw, re.I))
    checked_bags_fee = bool(re.search(r'Available for fee\s*:\s*Checked bags', raw, re.I))
    non_refundable = bool(re.search(r'This ticket is non-refundable|Refunds and ticket changes are not permitted', raw, re.I))

    days_until = None
    if outbound_date:
        try:
            dt = datetime.strptime(outbound_date, '%a, %b %d, %Y').replace(tzinfo=ny)
            days_until = (dt.date() - now.date()).days
        except Exception:
            pass

    if days_until is not None and days_until < 0:
        return None

    return {
        'trip_id': trip_id,
        'outbound_date': outbound_date,
        'outbound_dep': outbound_dep,
        'outbound_arr': outbound_arr,
        'outbound_num': outbound_num,
        'return_date': return_date,
        'return_dep': return_dep,
        'return_arr': return_arr,
        'return_num': return_num,
        'airline_conf': airline_conf,
        'travelers': [t.strip() for t in travelers if t.strip()],
        'total_cost': total_cost,
        'points': points,
        'billed': billed,
        'seats_missing': seats_missing,
        'checked_bags_fee': checked_bags_fee,
        'non_refundable': non_refundable,
        'days_until': days_until,
    }


trip = None
for mid in search_ids():
    parsed = parse_trip(get_msg(mid))
    if not parsed or not parsed.get('trip_id'):
        continue
    if parsed.get('days_until') is None:
        continue
    trip = parsed
    break

print('<section class="card">')
print('<h2>Trip Logistics</h2>')

if not trip:
    print('<p class="muted">No recent trip logistics found.</p>')
    print('</section>')
    print('__SUMMARY__No current trip logistics detected.')
    print('__NEXT_ACTION__')
    print('__HELP_IDEAS__')
    raise SystemExit

summary = []
if trip.get('days_until') is not None:
    if trip['days_until'] >= 0:
        summary.append(f"Florida trip is {trip['days_until']} day(s) away")
if trip.get('outbound_date'):
    summary.append(f"leave {trip['outbound_date']}")
if trip.get('seats_missing'):
    summary.append('seat selection still looks unresolved')

print('<p><strong>What matters:</strong> ' + html.escape('. '.join(summary)) + '.</p>')
print('<ul>')
print(f"<li><strong>Outbound:</strong> {html.escape(trip.get('outbound_date',''))} · {html.escape(trip.get('outbound_num','JetBlue'))} · {html.escape(trip.get('outbound_dep',''))} EWR → {html.escape(trip.get('outbound_arr',''))} MCO</li>")
print(f"<li><strong>Return:</strong> {html.escape(trip.get('return_date',''))} · {html.escape(trip.get('return_num','JetBlue'))} · {html.escape(trip.get('return_dep',''))} MCO → {html.escape(trip.get('return_arr',''))} EWR</li>")
trav = ', '.join(trip.get('travelers', []))
if trav:
    print(f"<li><strong>Travelers:</strong> {html.escape(trav)}</li>")
if trip.get('airline_conf'):
    print(f"<li><strong>Airline confirmation:</strong> {html.escape(trip['airline_conf'])}</li>")
if trip.get('seats_missing'):
    print('<li><strong>Risk:</strong> seat selection / assignments still need attention.</li>')
if trip.get('checked_bags_fee'):
    print('<li><strong>Bag note:</strong> carry-on is included; checked bags may cost extra.</li>')
print('</ul>')

next_actions = []
help_ideas = []
if trip.get('seats_missing'):
    next_actions.append('Choose seats or confirm whether JetBlue will only assign them at check-in.')
    help_ideas.append('I can turn this into a direct reminder and keep flagging it until it is handled.')
if trip.get('days_until') is not None and trip['days_until'] <= 4:
    next_actions.append('Confirm airport logistics: when to leave home, parking/Uber plan, and child travel timing.')
    help_ideas.append('I can build a departure-day plan with target leave time and a simple packing checklist.')
if trip.get('checked_bags_fee'):
    next_actions.append('Decide carry-on only vs checked bag before the last-minute scramble.')
    help_ideas.append('I can make a tiny travel checklist organized by carry-on, kid gear, and must-not-forget items.')
if trip.get('non_refundable'):
    next_actions.append('Avoid any loose itinerary assumptions — this trip looks non-refundable.')

print('__SUMMARY__' + '. '.join(summary) + '.')
print('__NEXT_ACTION__' + ' | '.join(next_actions[:3]))
print('__HELP_IDEAS__' + ' | '.join(help_ideas[:3]))
PY
