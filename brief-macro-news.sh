#!/bin/bash
set -euo pipefail
export TZ="America/New_York"

python3 - <<'PY'
import urllib.request, urllib.parse, json, ssl, re, html
ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

def fetch_json(url):
    req = urllib.request.Request(url, headers={'User-Agent':'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=20, context=ssl_ctx) as r:
        return json.loads(r.read().decode('utf-8', 'ignore'))

def esc(s):
    return str(s).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')

queries = [
    ('rates', 'fed inflation treasury yields jobs market'),
    ('commodities', 'oil opec copper commodities market inflation'),
    ('crypto', 'bitcoin crypto etf regulation market'),
    ('ai', 'semiconductor ai nvidia datacenter market'),
]

items = []
for bucket, q in queries:
    try:
        data = fetch_json('https://hnrss.org/newest.jsonfeed?q=' + urllib.parse.quote(q))
        for item in data.get('items', [])[:8]:
            title = (item.get('title') or '').strip()
            if not title:
                continue
            items.append({'bucket': bucket, 'title': title})
    except Exception:
        pass

seen = set()
filtered = []
for item in items:
    title = item['title']
    low = title.lower()
    if low in seen:
        continue
    if any(x in low for x in ['sponsor','podcast','youtube','reddit','hacker news']):
        continue
    if not any(k in low for k in ['fed','inflation','treasury','yield','oil','copper','bitcoin','crypto','etf','semiconductor','ai','nvidia','jobs','opec','tariff','economy','market']):
        continue
    seen.add(low)
    filtered.append(item)

priority = []
for item in filtered:
    low = item['title'].lower()
    score = 0
    if any(k in low for k in ['fed','inflation','treasury','yield','jobs']): score += 5
    if any(k in low for k in ['oil','copper','opec','commodity']): score += 4
    if any(k in low for k in ['bitcoin','crypto','etf']): score += 3
    if any(k in low for k in ['semiconductor','ai','nvidia']): score += 3
    priority.append((score, item))
priority.sort(key=lambda x: x[0], reverse=True)
selected = [x[1] for x in priority[:6]]

reads = []
for item in selected:
    t = item['title'].lower()
    if any(k in t for k in ['fed','inflation','treasury','yield','jobs']):
        reads.append('Rates/inflation headlines are still the cleanest macro override on growth multiples.')
    elif any(k in t for k in ['oil','opec','copper','commodity']):
        reads.append('Commodity headlines matter mainly if they start changing the inflation/rates conversation, not by themselves.')
    elif any(k in t for k in ['bitcoin','crypto','etf']):
        reads.append('Crypto headlines are useful mostly as a read-through on risk appetite, not because they directly price your watchlist.')
    elif any(k in t for k in ['semiconductor','ai','nvidia']):
        reads.append('AI/semi headlines matter when they confirm demand durability, not when they just repeat the theme.')

seen_reads = []
for r in reads:
    if r not in seen_reads:
        seen_reads.append(r)

summary = seen_reads[0] if seen_reads else 'Macro headlines are only useful when they change the market regime or the rate narrative; otherwise price action deserves more trust.'

print('<section class="card">')
print('<h2>Macro News</h2>')
print('<p><strong>What matters:</strong> ' + esc(summary) + '</p>')
print('<h3>Headlines Worth Your Time</h3>')
print('<ul>')
if selected:
    for item in selected[:5]:
        print('<li>' + esc(item['title']) + '</li>')
else:
    print('<li class="muted">No clean macro headlines passed the filter.</li>')
print('</ul>')
print('<h3>Read-Through</h3>')
print('<ul>')
for r in seen_reads[:3]:
    print('<li>' + esc(r) + '</li>')
if not seen_reads:
    print('<li>Macro headlines are only useful when they change regime, liquidity, or rate expectations. Otherwise they are theater.</li>')
print('</ul>')
print('</section>')
print('__SUMMARY__' + summary)
PY
