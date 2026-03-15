#!/bin/bash
set -euo pipefail
export TZ="America/New_York"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

python3 - <<'PY'
import json, urllib.request, urllib.parse, ssl, re
ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

watchlist = [
    ("COPX", "Global X Copper Miners ETF"),
    ("VRT", "Vertiv Holdings Co"),
    ("JMIA", "Jumia Technologies AG"),
    ("NVDA", "NVIDIA Corporation"),
    ("RBRK", "Rubrik, Inc."),
    ("AMZN", "Amazon.com, Inc."),
    ("MELI", "MercadoLibre, Inc."),
    ("CRWD", "CrowdStrike Holdings, Inc."),
    ("ALAB", "Astera Labs, Inc."),
    ("NOW", "ServiceNow, Inc."),
    ("SITM", "SiTime Corporation"),
    ("AMAT", "Applied Materials, Inc."),
    ("DOCN", "DigitalOcean Holdings, Inc."),
    ("NBIS", "Nebius Group N.V."),
]

def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent":"Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=20, context=ssl_ctx) as r:
        return json.loads(r.read().decode('utf-8', 'ignore'))

def esc(s):
    return str(s).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')

def fmt_pct(v):
    if v is None:
        return 'n/a'
    return f'{v:+.1f}%'

def fmt_price(v):
    if v is None:
        return 'n/a'
    return f'${v:,.2f}' if v < 1000 else f'${v:,.0f}'

def fmp_quote(symbols):
    out = {}
    try:
        url = 'https://financialmodelingprep.com/api/v3/quote/' + ','.join(symbols) + '?apikey=demo'
        data = fetch_json(url)
        for item in data:
            out[item.get('symbol')] = {
                'price': item.get('price'),
                'chg': item.get('changesPercentage'),
            }
    except Exception:
        pass
    return out

def coingecko():
    out = {}
    try:
        url = 'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&price_change_percentage=24h&ids=bitcoin,ethereum,solana'
        data = fetch_json(url)
        for item in data:
            out[item['symbol'].upper()] = {
                'price': item.get('current_price'),
                'chg': item.get('price_change_percentage_24h'),
            }
    except Exception:
        pass
    return out

def hnrss(query):
    try:
        url = 'https://hnrss.org/newest.jsonfeed?q=' + urllib.parse.quote(query)
        data = fetch_json(url)
        return [x.get('title','') for x in data.get('items',[])]
    except Exception:
        return []

symbols = [x[0] for x in watchlist] + ['SPY','QQQ','TLT','GLD','DBC']
quotes = fmp_quote(symbols)
crypto = coingecko()
macro_news = hnrss('fed inflation yields oil bitcoin semiconductor ai markets')

spy = quotes.get('SPY', {}).get('chg')
qqq = quotes.get('QQQ', {}).get('chg')
tlt = quotes.get('TLT', {}).get('chg')
gld = quotes.get('GLD', {}).get('chg')
dbc = quotes.get('DBC', {}).get('chg')
btc = crypto.get('BTC', {}).get('chg')

macro_lines = []
if spy is not None and qqq is not None:
    if qqq > spy + 0.5:
        macro_lines.append('Growth is leading the tape, which is the friendliest backdrop for your AI and quality-software names.')
    elif spy > qqq + 0.5:
        macro_lines.append('This is broader risk-taking, not just mega-cap tech worship, which matters for cyclicals and second-order winners.')
if tlt is not None:
    if tlt > 0.7:
        macro_lines.append('Bonds are helping, so duration-heavy growth has macro air cover.')
    elif tlt < -0.7:
        macro_lines.append('Rates are leaning against the market, which is the cleanest reason high-multiple names can suddenly feel heavy.')
if dbc is not None and dbc > 0.8:
    macro_lines.append('Commodities are firm enough that copper/cycle exposure still deserves attention.')
if gld is not None and gld > 0.8:
    macro_lines.append('Gold strength says some caution is still being priced under the hood.')
if btc is not None:
    if btc > 2.5:
        macro_lines.append('Crypto is risk-on, which usually confirms appetite for speculative growth further out on the curve.')
    elif btc < -2.5:
        macro_lines.append('Crypto is rolling over, which is often where risk appetite weakens before equities admit it.')
if not macro_lines:
    macro_lines.append('No clean macro regime shift is obvious, so the edge is in interpretation and selectivity rather than index gawking.')

rows = []
for ticker, name in watchlist:
    q = quotes.get(ticker, {})
    rows.append({'ticker': ticker, 'name': name, 'price': q.get('price'), 'chg': q.get('chg')})

leaders = sorted([r for r in rows if r['chg'] is not None], key=lambda r: r['chg'], reverse=True)[:5]
laggards = sorted([r for r in rows if r['chg'] is not None], key=lambda r: r['chg'])[:4]

interpretation = []
for r in rows:
    t, c = r['ticker'], r['chg']
    if c is None:
        continue
    if t in ['NVDA','ALAB','AMAT','SITM'] and c > 2:
        interpretation.append(f'{t} is confirming that semi/AI leadership still has sponsorship.')
    elif t in ['NVDA','ALAB','AMAT','SITM'] and c < -2:
        interpretation.append(f'{t} is weak enough to question whether AI leadership is broadening or cracking.')
    elif t in ['CRWD','RBRK','NOW','DOCN'] and c > 2:
        interpretation.append(f'{t} says quality software/cyber is still being accumulated, not just admired.')
    elif t == 'VRT' and c > 2:
        interpretation.append('VRT strength keeps the AI infrastructure trade alive beyond the obvious chip names.')
    elif t == 'COPX' and c > 2:
        interpretation.append('COPX acting well means cyclicals and resource leverage still have a pulse.')
    elif t in ['JMIA','NBIS'] and abs(c) > 4:
        interpretation.append(f'{t} is moving like a true high-beta special situation, so sizing matters more than storytelling.')
interpretation = interpretation[:4] or ['The watchlist is mixed, so the real job is separating durable leadership from fun-looking noise.']

macro_news = [x for x in macro_news if any(k in x.lower() for k in ['fed','inflation','yield','oil','bitcoin','semiconductor','ai','market'])][:4]
if not macro_news:
    macro_news = ['No clean macro headline edge right now; price action is probably telling the truth faster than pundits are.']

print('<section class="card">')
print('<h2>Markets / Macro</h2>')
print('<p><strong>What matters:</strong> ' + esc(macro_lines[0]) + '</p>')
print('<ul>')
for line in macro_lines[1:4]:
    print('<li>' + esc(line) + '</li>')
print('</ul>')
print('<h3>Macro Pulse</h3>')
print('<ul>')
for line in macro_news:
    print('<li>' + esc(line) + '</li>')
print('</ul>')
print('<h3>TradFi Watchlist</h3>')
print('<ul>')
if leaders:
    for r in leaders:
        print(f"<li><strong>{esc(r['ticker'])}</strong> {esc(fmt_price(r['price']))} ({esc(fmt_pct(r['chg']))}) — acting relatively well.</li>")
if laggards:
    shown = {r['ticker'] for r in leaders}
    for r in laggards:
        if r['ticker'] not in shown:
            print(f"<li><strong>{esc(r['ticker'])}</strong> {esc(fmt_price(r['price']))} ({esc(fmt_pct(r['chg']))}) — under relative pressure.</li>")
if not leaders and not laggards:
    print('<li class="muted">Live quote feed unavailable, but the section is wired and will degrade gracefully instead of breaking the brief.</li>')
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
    if not item:
        continue
    note = 'risk appetite is constructive.' if (item.get('chg') or 0) > 2 else ('risk appetite is softening.' if (item.get('chg') or 0) < -2 else 'mostly noise unless it starts to trend.')
    print(f"<li><strong>{sym}</strong> {esc(fmt_price(item.get('price')))} ({esc(fmt_pct(item.get('chg')))}) — {esc(note)}</li>")
if not crypto:
    print('<li class="muted">Crypto feed unavailable.</li>')
print('</ul>')
print('</section>')
print('__SUMMARY__' + macro_lines[0])
PY
