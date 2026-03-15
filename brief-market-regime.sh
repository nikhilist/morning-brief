#!/bin/bash
set -euo pipefail
export TZ="America/New_York"

python3 - <<'PY'
import urllib.request, ssl
ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE
symbols = {
    'SPY':'spy.us','QQQ':'qqq.us','TLT':'tlt.us','GLD':'gld.us','DBC':'dbc.us','XLF':'xlf.us','IWM':'iwm.us','SOXX':'soxx.us'
}

def fetch_text(url):
    req = urllib.request.Request(url, headers={'User-Agent':'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=20, context=ssl_ctx) as r:
        return r.read().decode('utf-8','ignore')

def quote(sym):
    raw = fetch_text(f'https://stooq.com/q/l/?s={sym}&i=d').strip().split(',')
    if len(raw) < 7:
        return None
    o = float(raw[4]); c = float(raw[6])
    return ((c/o)-1)*100 if o else None

def esc(s):
    return str(s).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')

q = {k: quote(v) for k,v in symbols.items()}
lines = []
if q['QQQ'] is not None and q['SPY'] is not None:
    if q['QQQ'] > q['SPY'] + 0.5:
        lines.append('Growth is outperforming the broad market, so duration and AI still have the cleaner tape.')
    elif q['SPY'] > q['QQQ'] + 0.5:
        lines.append('The market is broader than big-tech autopilot today, which usually improves the opportunity set.')
if q['IWM'] is not None and q['SPY'] is not None and q['IWM'] > q['SPY'] + 0.5:
    lines.append('Small caps are participating, which usually means risk appetite is healthier than headlines suggest.')
if q['TLT'] is not None:
    if q['TLT'] > 0.7:
        lines.append('Bonds are helping, which gives expensive growth names more room to work.')
    elif q['TLT'] < -0.7:
        lines.append('Rates are pressing upward again, which is the cleanest macro threat to high-multiple names.')
if q['SOXX'] is not None and q['QQQ'] is not None:
    if q['SOXX'] > q['QQQ'] + 0.5:
        lines.append('Semis are carrying more than their share, so the AI complex still matters disproportionately.')
if q['DBC'] is not None and q['GLD'] is not None:
    if q['DBC'] > 0.8:
        lines.append('Commodity strength keeps the reflation/copper angle alive.')
    elif q['GLD'] > 0.8:
        lines.append('Gold acting better than cyclicals hints at a more defensive undercurrent.')

summary = lines[0] if lines else 'No dominant market regime signal is obvious, so narrative confidence should stay lower than stock-specific conviction.'

print('<section class="card">')
print('<h2>Market Regime</h2>')
print('<p><strong>What matters:</strong> ' + esc(summary) + '</p>')
print('<ul>')
for line in lines[1:5]:
    print('<li>' + esc(line) + '</li>')
if not lines:
    print('<li>When regime is mixed, the edge comes from selectivity and sizing rather than broad directional swagger.</li>')
print('</ul>')
print('</section>')
print('__SUMMARY__' + summary)
PY
