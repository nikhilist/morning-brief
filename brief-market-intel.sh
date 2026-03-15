#!/bin/bash
set -euo pipefail
export TZ="America/New_York"

python3 - <<'PY'
import urllib.request, urllib.parse, json, ssl, html
ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

watchlist = [
    ('COPX', 'Global X Copper Miners ETF'), ('VRT', 'Vertiv Holdings Co'), ('JMIA', 'Jumia Technologies AG'),
    ('NVDA', 'NVIDIA Corporation'), ('RBRK', 'Rubrik, Inc.'), ('AMZN', 'Amazon.com, Inc.'),
    ('MELI', 'MercadoLibre, Inc.'), ('CRWD', 'CrowdStrike Holdings, Inc.'), ('ALAB', 'Astera Labs, Inc.'),
    ('NOW', 'ServiceNow, Inc.'), ('SITM', 'SiTime Corporation'), ('AMAT', 'Applied Materials, Inc.'),
    ('DOCN', 'DigitalOcean Holdings, Inc.'), ('NBIS', 'Nebius Group N.V.')
]
bench = {'SPY':'spy.us','QQQ':'qqq.us','TLT':'tlt.us','GLD':'gld.us','DBC':'dbc.us','IWM':'iwm.us','SOXX':'soxx.us'}
stooq_map = {
    'COPX':'copx.us','VRT':'vrt.us','JMIA':'jmia.us','NVDA':'nvda.us','RBRK':'rbrk.us','AMZN':'amzn.us',
    'MELI':'meli.us','CRWD':'crwd.us','ALAB':'alab.us','NOW':'now.us','SITM':'sitm.us','AMAT':'amat.us',
    'DOCN':'docn.us','NBIS':'nbis.us'
}

def esc(s):
    return html.escape(str(s))

def fmt_pct(v):
    return 'n/a' if v is None else f'{v:+.1f}%'

def fmt_price(v):
    if v is None: return 'n/a'
    return f'${v:,.2f}' if v < 1000 else f'${v:,.0f}'

def fetch_text(url):
    req = urllib.request.Request(url, headers={'User-Agent':'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=20, context=ssl_ctx) as r:
        return r.read().decode('utf-8','ignore')

def fetch_json(url):
    return json.loads(fetch_text(url))

def stooq_quote(symbol):
    try:
        raw = fetch_text(f'https://stooq.com/q/l/?s={symbol}&i=d').strip().split(',')
        if len(raw) < 7: return None
        o = float(raw[4]); c = float(raw[6])
        return {'price': c, 'chg': ((c/o)-1)*100 if o else None}
    except Exception:
        return None

quotes = {k: stooq_quote(v) for k,v in {**bench, **stooq_map}.items()}

crypto = {}
try:
    data = fetch_json('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&price_change_percentage=24h&ids=bitcoin,ethereum,solana')
    for item in data:
        crypto[item['symbol'].upper()] = {'price': item.get('current_price'), 'chg': item.get('price_change_percentage_24h')}
except Exception:
    pass

spy = (quotes.get('SPY') or {}).get('chg')
qqq = (quotes.get('QQQ') or {}).get('chg')
tlt = (quotes.get('TLT') or {}).get('chg')
gld = (quotes.get('GLD') or {}).get('chg')
dbc = (quotes.get('DBC') or {}).get('chg')
iwm = (quotes.get('IWM') or {}).get('chg')
soxx = (quotes.get('SOXX') or {}).get('chg')
btc = (crypto.get('BTC') or {}).get('chg')

regime = []
if spy is not None and qqq is not None:
    if qqq > spy + 0.5:
        regime.append('Growth is leading, so AI/semis still have the cleaner tape.')
    elif spy > qqq + 0.5:
        regime.append('This is broader risk appetite, not just mega-cap autopilot.')
if iwm is not None and spy is not None and iwm > spy + 0.5:
    regime.append('Small caps are participating, which usually means risk appetite is healthier than headlines suggest.')
if tlt is not None:
    if tlt > 0.7:
        regime.append('Bonds are helping, which gives expensive growth more room.')
    elif tlt < -0.7:
        regime.append('Rates are leaning the wrong way for high-multiple names.')
if soxx is not None and qqq is not None and soxx > qqq + 0.5:
    regime.append('Semis are doing more than their share of the lifting.')
if dbc is not None and dbc > 0.8:
    regime.append('Commodity strength keeps the copper/reflation angle alive.')
if gld is not None and gld > 0.8:
    regime.append('Gold strength hints at a more defensive undercurrent.')
if btc is not None and btc > 2.5:
    regime.append('Crypto is risk-on, which usually confirms appetite for speculation elsewhere.')
summary = regime[0] if regime else 'No dominant regime is obvious, so selectivity matters more than market storytelling.'

rows = []
for ticker, name in watchlist:
    q = quotes.get(ticker) or {}
    rows.append({'ticker': ticker, 'price': q.get('price'), 'chg': q.get('chg')})
negative = sorted([r for r in rows if r['chg'] is not None and r['chg'] < 0], key=lambda r: r['chg'])[:5]
positive = sorted([r for r in rows if r['chg'] is not None and r['chg'] >= 0], key=lambda r: r['chg'], reverse=True)[:3]

interpretation = []
for r in rows:
    t, c = r['ticker'], r['chg']
    if c is None: continue
    if t in ['NVDA','ALAB','AMAT','SITM'] and c < -2:
        interpretation.append(f'{t} softness is enough to question whether AI leadership is narrowing.')
    elif t in ['CRWD','RBRK','NOW','DOCN'] and c < -2:
        interpretation.append(f'{t} weakness says software quality still needs fresh reasons to work.')
    elif t == 'COPX' and c < -2:
        interpretation.append('COPX weakness says the market is not paying for reflation/copper torque right now.')
    elif t in ['JMIA','NBIS'] and abs(c) > 4:
        interpretation.append(f'{t} is moving like a high-beta special situation, so sizing matters more than conviction theatre.')
if not interpretation:
    interpretation.append('The watchlist is mixed, so the real edge is separating durable leaders from noise.')
interpretation = interpretation[:4]

print('<section class="card">')
print('<h2>Market Intelligence</h2>')
print('<p><strong>What matters:</strong> ' + esc(summary) + '</p>')
print('<ul>')
for line in regime[1:4]:
    print('<li>' + esc(line) + '</li>')
for line in interpretation[:2]:
    print('<li>' + esc(line) + '</li>')
print('</ul>')
print('<h3>Watchlist Pressure</h3>')
print('<ul>')
if negative:
    for r in negative:
        print(f"<li><strong>{esc(r['ticker'])}</strong> {esc(fmt_price(r['price']))} ({esc(fmt_pct(r['chg']))}) — under pressure.</li>")
elif positive:
    for r in positive:
        print(f"<li><strong>{esc(r['ticker'])}</strong> {esc(fmt_price(r['price']))} ({esc(fmt_pct(r['chg']))}) — showing relative strength.</li>")
else:
    print('<li class="muted">Live watchlist data unavailable.</li>')
print('</ul>')
print('<h3>Crypto</h3>')
print('<ul>')
for sym in ['BTC','ETH','SOL']:
    item = crypto.get(sym)
    if item:
        note = 'risk appetite is constructive.' if (item.get('chg') or 0) > 2 else ('risk appetite is softening.' if (item.get('chg') or 0) < -2 else 'mostly noise unless the move extends.')
        print(f"<li><strong>{sym}</strong> {esc(fmt_price(item.get('price')))} ({esc(fmt_pct(item.get('chg')))}) — {esc(note)}</li>")
if not crypto:
    print('<li class="muted">Crypto feed unavailable.</li>')
print('</ul>')
print('</section>')
print('__SUMMARY__' + summary)
PY
