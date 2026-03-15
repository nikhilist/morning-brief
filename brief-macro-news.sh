#!/bin/bash
set -euo pipefail
export TZ="America/New_York"

python3 - <<'PY'
import urllib.request, urllib.parse, json, ssl, re
ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

def fetch_text(url):
    req = urllib.request.Request(url, headers={'User-Agent':'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=20, context=ssl_ctx) as r:
        return r.read().decode('utf-8', 'ignore')

def fetch_json(url):
    return json.loads(fetch_text(url))

def esc(s):
    return str(s).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')

def stooq_close(symbol):
    try:
        raw = fetch_text(f'https://stooq.com/q/l/?s={symbol}&i=d').strip().split(',')
        if len(raw) < 7:
            return None
        return float(raw[6]), float(raw[4])
    except Exception:
        return None, None

# No-key macro proxies
us10, us10_open = stooq_close('10us.us')
us2, us2_open = stooq_close('2us.us')
gold, gold_open = stooq_close('gold')
wtioil, wtioil_open = stooq_close('cl.f')

headlines = []
reads = []

if us10 is not None and us2 is not None:
    curve = us10 - us2
    if curve > 0.25:
        reads.append('The curve is positively sloped enough that recession panic is not the main market story right now.')
    elif curve < -0.25:
        reads.append('The curve is still inverted, which means late-cycle anxiety and rate-cut hopes are both hanging around.')
    headlines.append(f'10Y Treasury proxy: {us10:.2f}%')
    headlines.append(f'2Y Treasury proxy: {us2:.2f}%')
    headlines.append(f'2s10s curve: {curve:+.2f} pts')

if us10 is not None and us10_open not in (None, 0):
    d10 = us10 - us10_open
    if d10 > 0.08:
        reads.append('Long yields are backing up enough to matter for valuations, especially expensive growth.')
    elif d10 < -0.08:
        reads.append('Long yields are easing, which is the cleanest macro support for duration-heavy winners.')

if wtioil is not None and wtioil_open not in (None, 0):
    doil = ((wtioil / wtioil_open) - 1) * 100
    headlines.append(f'WTI crude proxy: ${wtioil:.2f} ({doil:+.1f}% today)')
    if doil > 2.5:
        reads.append('Oil is moving enough to become macro-relevant, mainly through inflation expectations rather than growth optimism.')
    elif doil < -2.5:
        reads.append('Oil softness takes some pressure off the inflation scare path.')

if gold is not None and gold_open not in (None, 0):
    dgold = ((gold / gold_open) - 1) * 100
    headlines.append(f'Gold proxy: ${gold:.2f} ({dgold:+.1f}% today)')
    if dgold > 1.0:
        reads.append('Gold strength hints at a defensive undercurrent even if equities are still functioning.')

# Secondary color only
feed_titles = []
for q in [
    'site:reuters.com fed inflation treasury yields markets',
    'site:cnbc.com treasury yields inflation fed markets',
    'site:marketwatch.com fed inflation treasury yields markets',
]:
    try:
        data = fetch_json('https://hnrss.org/newest.jsonfeed?q=' + urllib.parse.quote(q))
        for item in data.get('items', [])[:6]:
            t = (item.get('title') or '').strip()
            if t and t not in feed_titles:
                feed_titles.append(t)
    except Exception:
        pass
feed_titles = [t for t in feed_titles if any(k in t.lower() for k in ['fed','inflation','treasury','yield','oil','jobs','economy','market'])][:4]

summary = reads[0] if reads else 'Macro should be read through yields, energy, and defensive hedges before it is read through headlines.'

print('<section class="card">')
print('<h2>Macro News</h2>')
print('<p><strong>What matters:</strong> ' + esc(summary) + '</p>')
print('<h3>Data That Actually Matters</h3>')
print('<ul>')
for h in headlines[:5]:
    print('<li>' + esc(h) + '</li>')
if not headlines:
    print('<li class="muted">Macro data pull unavailable.</li>')
print('</ul>')
print('<h3>Read-Through</h3>')
print('<ul>')
for r in reads[:4]:
    print('<li>' + esc(r) + '</li>')
if not reads:
    print('<li>Without a move in yields, energy, or defensive hedges, most macro chatter is theater.</li>')
print('</ul>')
print('<h3>Secondary Headlines</h3>')
print('<ul>')
for t in feed_titles:
    print('<li>' + esc(t) + '</li>')
if not feed_titles:
    print('<li class="muted">No secondary headlines cleared the relevance bar.</li>')
print('</ul>')
print('</section>')
print('__SUMMARY__' + summary)
PY
