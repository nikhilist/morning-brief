#!/bin/bash
set -euo pipefail
export TZ="America/New_York"

python3 - <<'PY'
import urllib.request, urllib.parse, json, ssl, re
from datetime import datetime
ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

FRED_KEY = 'fred'

def fetch_text(url):
    req = urllib.request.Request(url, headers={'User-Agent':'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=20, context=ssl_ctx) as r:
        return r.read().decode('utf-8', 'ignore')

def fetch_json(url):
    return json.loads(fetch_text(url))

def esc(s):
    return str(s).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')

def fred_latest(series):
    url = f'https://api.stlouisfed.org/fred/series/observations?series_id={series}&api_key={FRED_KEY}&file_type=json&sort_order=desc&limit=3'
    try:
        data = fetch_json(url)
        vals = []
        for obs in data.get('observations', []):
            v = obs.get('value')
            if v not in ('.', None, ''):
                vals.append((obs.get('date'), float(v)))
        return vals
    except Exception:
        return []

def delta_text(curr, prev, unit=''):
    if curr is None or prev is None:
        return None
    d = curr - prev
    sign = '+' if d > 0 else ''
    return f'{sign}{d:.2f}{unit}'

series = {
    'DGS10': '10Y Treasury',
    'DGS2': '2Y Treasury',
    'T10YIE': '10Y breakeven inflation',
    'DFF': 'Fed funds effective',
    'UNRATE': 'Unemployment rate',
    'CPIAUCSL': 'CPI index',
    'DCOILWTICO': 'WTI crude',
}

latest = {k: fred_latest(k) for k in series}
reads = []
headlines = []

v10 = latest['DGS10'][0][1] if len(latest['DGS10']) > 0 else None
v10_prev = latest['DGS10'][1][1] if len(latest['DGS10']) > 1 else None
v2 = latest['DGS2'][0][1] if len(latest['DGS2']) > 0 else None
v2_prev = latest['DGS2'][1][1] if len(latest['DGS2']) > 1 else None
be = latest['T10YIE'][0][1] if len(latest['T10YIE']) > 0 else None
be_prev = latest['T10YIE'][1][1] if len(latest['T10YIE']) > 1 else None
oil = latest['DCOILWTICO'][0][1] if len(latest['DCOILWTICO']) > 0 else None
oil_prev = latest['DCOILWTICO'][1][1] if len(latest['DCOILWTICO']) > 1 else None
ff = latest['DFF'][0][1] if len(latest['DFF']) > 0 else None
unrate = latest['UNRATE'][0][1] if len(latest['UNRATE']) > 0 else None
cpi = latest['CPIAUCSL'][0][1] if len(latest['CPIAUCSL']) > 0 else None
cpi_prev = latest['CPIAUCSL'][1][1] if len(latest['CPIAUCSL']) > 1 else None

if v10 is not None and v2 is not None:
    curve = v10 - v2
    if curve > 0.25:
        reads.append('The curve is positively sloped enough that recession panic is not the main market story right now.')
    elif curve < -0.25:
        reads.append('The curve is still inverted, which means rate-cut hopes and late-cycle anxiety are both hanging around.')

if v10 is not None and v10_prev is not None:
    dv = v10 - v10_prev
    if dv > 0.08:
        reads.append('Long yields are backing up enough to matter for valuations, especially expensive growth.')
    elif dv < -0.08:
        reads.append('Long yields are easing, which is the cleanest macro support for duration-heavy winners.')
    headlines.append(f'10Y Treasury: {v10:.2f}% ({dv:+.2f} pts vs prior print)')

if be is not None and be_prev is not None:
    db = be - be_prev
    if db > 0.08:
        reads.append('Breakeven inflation is firming, so the market is not fully relaxed on inflation risk.')
    elif db < -0.08:
        reads.append('Breakeven inflation is easing, which helps keep the rate narrative from getting worse.')
    headlines.append(f'10Y breakeven inflation: {be:.2f}% ({db:+.2f} pts)')

if oil is not None and oil_prev is not None:
    doil = ((oil / oil_prev) - 1) * 100 if oil_prev else 0
    if doil > 2.5:
        reads.append('Oil is moving enough to become macro-relevant, mainly through inflation expectations rather than growth optimism.')
    elif doil < -2.5:
        reads.append('Oil softness takes some pressure off the inflation scare path.')
    headlines.append(f'WTI crude: ${oil:.2f} ({doil:+.1f}% vs prior print)')

if ff is not None:
    headlines.append(f'Fed funds effective: {ff:.2f}%')
if unrate is not None:
    headlines.append(f'Unemployment rate: {unrate:.1f}%')
if cpi is not None and cpi_prev is not None:
    dcpi = ((cpi / cpi_prev) - 1) * 100 if cpi_prev else 0
    headlines.append(f'CPI index latest print: {cpi:.2f} ({dcpi:+.2f}% vs prior print)')

# Secondary color only
feed_titles = []
for q in [
    'site:reuters.com fed inflation treasury yields markets',
    'site:cnbc.com treasury yields inflation fed markets',
    'site:marketwatch.com fed inflation treasury yields markets',
    'site:investing.com inflation treasury yields fed markets',
]:
    try:
        data = fetch_json('https://hnrss.org/newest.jsonfeed?q=' + urllib.parse.quote(q))
        for item in data.get('items', [])[:5]:
            t = (item.get('title') or '').strip()
            if t and t not in feed_titles:
                feed_titles.append(t)
    except Exception:
        pass

feed_titles = [t for t in feed_titles if any(k in t.lower() for k in ['fed','inflation','treasury','yield','oil','jobs','economy','market'])][:4]
summary = reads[0] if reads else 'Macro should be read through rates, inflation expectations, and oil before it is read through headlines.'

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
    print('<li>Without a move in rates, inflation expectations, or energy, most macro chatter is theater.</li>')
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
