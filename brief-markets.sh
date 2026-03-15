#!/bin/bash
set -euo pipefail
export TZ="America/New_York"

python3 - <<'PY'
import urllib.request, urllib.parse, json, ssl
ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

watchlist = [
    ('COPX', 'Global X Copper Miners ETF'),
    ('VRT', 'Vertiv Holdings Co'),
    ('JMIA', 'Jumia Technologies AG'),
    ('NVDA', 'NVIDIA Corporation'),
    ('RBRK', 'Rubrik, Inc.'),
    ('AMZN', 'Amazon.com, Inc.'),
    ('MELI', 'MercadoLibre, Inc.'),
    ('CRWD', 'CrowdStrike Holdings, Inc.'),
    ('ALAB', 'Astera Labs, Inc.'),
    ('NOW', 'ServiceNow, Inc.'),
    ('SITM', 'SiTime Corporation'),
    ('AMAT', 'Applied Materials, Inc.'),
    ('DOCN', 'DigitalOcean Holdings, Inc.'),
    ('NBIS', 'Nebius Group N.V.'),
]
bench = ['SPY', 'QQQ', 'TLT', 'GLD', 'DBC']
stooq_map = {
    'SPY': 'spy.us', 'QQQ': 'qqq.us', 'TLT': 'tlt.us', 'GLD': 'gld.us', 'DBC': 'dbc.us',
    'COPX': 'copx.us', 'VRT': 'vrt.us', 'JMIA': 'jmia.us', 'NVDA': 'nvda.us', 'RBRK': 'rbrk.us',
    'AMZN': 'amzn.us', 'MELI': 'meli.us', 'CRWD': 'crwd.us', 'ALAB': 'alab.us', 'NOW': 'now.us',
    'SITM': 'sitm.us', 'AMAT': 'amat.us', 'DOCN': 'docn.us', 'NBIS': 'nbis.us'
}

def esc(s):
    return str(s).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')

def fmt_pct(v):
    return 'n/a' if v is None else f'{v:+.1f}%'

def fmt_price(v):
    if v is None:
        return 'n/a'
    return f'${v:,.2f}' if v < 1000 else f'${v:,.0f}'

def fetch_text(url):
    req = urllib.request.Request(url, headers={'User-Agent':'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=20, context=ssl_ctx) as r:
        return r.read().decode('utf-8', 'ignore')

def fetch_json(url):
    return json.loads(fetch_text(url))

def stooq_quote(symbol):
    try:
        raw = fetch_text(f'https://stooq.com/q/l/?s={symbol}&i=d').strip()
        parts = raw.split(',')
        if len(parts) < 7:
            return None
        close = float(parts[6])
        open_ = float(parts[4])
        chg = ((close / open_) - 1) * 100 if open_ else None
        return {'price': close, 'chg': chg}
    except Exception:
        return None

quotes = {sym: stooq_quote(stooq_map[sym]) for sym in bench + [x[0] for x in watchlist]}

crypto = {}
try:
    data = fetch_json('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&price_change_percentage=24h&ids=bitcoin,ethereum,solana')
    for item in data:
        crypto[item['symbol'].upper()] = {'price': item.get('current_price'), 'chg': item.get('price_change_percentage_24h')}
except Exception:
    pass

macro_news = []
for query in ['fed inflation yields markets', 'bitcoin crypto markets', 'semiconductor ai markets']:
    try:
        data = fetch_json('https://hnrss.org/newest.jsonfeed?q=' + urllib.parse.quote(query))
        for item in data.get('items', []):
            title = item.get('title', '')
            if title and title not in macro_news:
                macro_news.append(title)
            if len(macro_news) >= 6:
                break
    except Exception:
        pass
    if len(macro_news) >= 6:
        break

spy = (quotes.get('SPY') or {}).get('chg')
qqq = (quotes.get('QQQ') or {}).get('chg')
tlt = (quotes.get('TLT') or {}).get('chg')
gld = (quotes.get('GLD') or {}).get('chg')
dbc = (quotes.get('DBC') or {}).get('chg')
btc = (crypto.get('BTC') or {}).get('chg')

macro_lines = []
if spy is not None and qqq is not None:
    if qqq > spy + 0.5:
        macro_lines.append('Growth is leading, so the tape still favors AI, semis, and quality duration over generic beta.')
    elif spy > qqq + 0.5:
        macro_lines.append('This is broader risk appetite, not just mega-cap tech autopilot, which is healthier for second-order names.')
if tlt is not None:
    if tlt > 0.7:
        macro_lines.append('Bonds are cooperating, which gives long-duration growth a cleaner macro backdrop.')
    elif tlt < -0.7:
        macro_lines.append('Rates are pushing back up, which is the simplest way expensive winners get punished.')
if dbc is not None and dbc > 0.8:
    macro_lines.append('Commodities have enough life that copper and cyclical reflation still matter.')
if gld is not None and gld > 0.8:
    macro_lines.append('Gold strength says some defensive caution is still alive underneath the surface.')
if btc is not None:
    if btc > 2.5:
        macro_lines.append('Crypto is acting risk-on, which usually confirms appetite for speculative growth elsewhere.')
    elif btc < -2.5:
        macro_lines.append('Crypto is fading, which is often where animal spirits crack first.')
if not macro_lines:
    macro_lines.append('No single macro regime is dominating, so stock selection matters more than big-picture chest-thumping.')

rows = []
for ticker, name in watchlist:
    q = quotes.get(ticker) or {}
    rows.append({'ticker': ticker, 'name': name, 'price': q.get('price'), 'chg': q.get('chg')})

positive = sorted([r for r in rows if r['chg'] is not None and r['chg'] >= 0], key=lambda r: r['chg'], reverse=True)[:5]
negative = sorted([r for r in rows if r['chg'] is not None and r['chg'] < 0], key=lambda r: r['chg'])[:5]
flat = sorted([r for r in rows if r['chg'] is not None and abs(r['chg']) < 0.75], key=lambda r: abs(r['chg']))[:3]

interpretation = []
for r in rows:
    t, c = r['ticker'], r['chg']
    if c is None:
        continue
    if t in ['NVDA','ALAB','AMAT','SITM'] and c > 2:
        interpretation.append(f'{t} is confirming that semi/AI leadership still has sponsorship.')
    elif t in ['NVDA','ALAB','AMAT','SITM'] and c < -2:
        interpretation.append(f'{t} is soft enough to question whether AI leadership is narrowing.')
    elif t in ['CRWD','RBRK','NOW','DOCN'] and c > 2:
        interpretation.append(f'{t} says quality software/cyber is still attracting real money.')
    elif t in ['CRWD','RBRK','NOW','DOCN'] and c < -2:
        interpretation.append(f'{t} weakness suggests the market is not forgiving software duration without fresh reasons.')
    elif t == 'VRT' and c > 2:
        interpretation.append('VRT strength keeps the AI infrastructure trade alive beyond the obvious chip winners.')
    elif t == 'COPX' and c > 2:
        interpretation.append('COPX strength says cyclicals and commodity leverage still have room to matter.')
    elif t == 'COPX' and c < -2:
        interpretation.append('COPX weakness says the market is not paying for reflation/copper torque right now.')
    elif t in ['JMIA','NBIS'] and abs(c) > 4:
        interpretation.append(f'{t} is moving like a high-beta special situation, so sizing discipline matters more than narrative confidence.')

if not interpretation:
    interpretation.append('The watchlist is mixed, so the real edge is distinguishing durable leadership from tourist trades.')
interpretation = interpretation[:4]

filtered_news = []
for title in macro_news:
    low = title.lower()
    if any(k in low for k in ['fed','inflation','yield','oil','bitcoin','crypto','semiconductor','ai','market','treasury']):
        filtered_news.append(title)
filtered_news = filtered_news[:4] or ['No clean macro headline edge right now; price action is probably more honest than commentary.']

print('<section class="card">')
print('<h2>Markets / Macro</h2>')
print('<p><strong>What matters:</strong> ' + esc(macro_lines[0]) + '</p>')
print('<ul>')
for line in macro_lines[1:4]:
    print('<li>' + esc(line) + '</li>')
print('</ul>')
print('<h3>Macro Pulse</h3>')
print('<ul>')
for line in filtered_news:
    print('<li>' + esc(line) + '</li>')
print('</ul>')
print('<h3>TradFi Watchlist</h3>')
print('<ul>')
for r in positive:
    print(f"<li><strong>{esc(r['ticker'])}</strong> {esc(fmt_price(r['price']))} ({esc(fmt_pct(r['chg']))}) — showing relative strength.</li>")
for r in negative:
    print(f"<li><strong>{esc(r['ticker'])}</strong> {esc(fmt_price(r['price']))} ({esc(fmt_pct(r['chg']))}) — under pressure.</li>")
if not positive and not negative:
    for r in flat:
        print(f"<li><strong>{esc(r['ticker'])}</strong> {esc(fmt_price(r['price']))} ({esc(fmt_pct(r['chg']))}) — basically flat.</li>")
if not positive and not negative and not flat:
    print('<li class="muted">Live quote feed unavailable.</li>')
print('</ul>')
print('<h3>Interpretation</h3>')
print('<ul>')
for line in interpretation:
    print('<li>' + esc(line) + '</li>')
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
print('__SUMMARY__' + macro_lines[0])
PY
