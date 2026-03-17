#!/bin/bash
set -euo pipefail
export TZ="America/New_York"

FETCHED_AT=$(date -Iseconds)

python3 - <<'PY'
import urllib.request, urllib.parse, json, ssl, html
ssl_ctx = ssl.create_default_context()
ssl_ctx.check_hostname = False
ssl_ctx.verify_mode = ssl.CERT_NONE

themes = {
    'AI / Semis': ['NVDA', 'ALAB', 'AMAT', 'SITM'],
    'Software / Cyber / Infra': ['CRWD', 'RBRK', 'NOW', 'DOCN'],
    'AI Infrastructure / Power / Datacenter': ['VRT'],
    'Consumer / Commerce Platforms': ['AMZN', 'MELI', 'JMIA'],
    'Commodities / Reflation': ['COPX'],
    'International / Special Situations': ['NBIS', 'JMIA'],
}
crypto_syms = ['BTC', 'ETH', 'SOL', 'HYPE']
bench = {'SPY':'spy.us','QQQ':'qqq.us','TLT':'tlt.us','GLD':'gld.us','DBC':'dbc.us','SOXX':'soxx.us'}
stooq_map = {
    'NVDA':'nvda.us','ALAB':'alab.us','AMAT':'amat.us','SITM':'sitm.us','CRWD':'crwd.us','RBRK':'rbrk.us',
    'NOW':'now.us','DOCN':'docn.us','VRT':'vrt.us','AMZN':'amzn.us','MELI':'meli.us','JMIA':'jmia.us',
    'COPX':'copx.us','NBIS':'nbis.us'
}
crypto_ids = {'BTC':'bitcoin','ETH':'ethereum','SOL':'solana','HYPE':'hyperliquid'}

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
    ids = ','.join(crypto_ids.values())
    data = fetch_json('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&price_change_percentage=24h&ids=' + ids)
    reverse = {v:k for k,v in crypto_ids.items()}
    for item in data:
        sym = reverse.get(item['id'])
        if sym:
            crypto[sym] = {'price': item.get('current_price'), 'chg': item.get('price_change_percentage_24h')}
except Exception:
    pass

spy = (quotes.get('SPY') or {}).get('chg')
qqq = (quotes.get('QQQ') or {}).get('chg')
tlt = (quotes.get('TLT') or {}).get('chg')
soxx = (quotes.get('SOXX') or {}).get('chg')
dbc = (quotes.get('DBC') or {}).get('chg')

regime = []
if spy is not None and qqq is not None:
    if qqq > spy + 0.5:
        regime.append('Growth is leading, so your AI and duration-heavy exposures still have the cleaner tape.')
    elif spy > qqq + 0.5:
        regime.append('The tape is broader than pure mega-cap leadership, which is healthier for second-order winners.')
if tlt is not None:
    if tlt > 0.7:
        regime.append('Bonds are helping, which is supportive for expensive long-duration names.')
    elif tlt < -0.7:
        regime.append('Rates are pressing the wrong way, which matters for high-multiple compounders.')
if soxx is not None and qqq is not None and soxx > qqq + 0.5:
    regime.append('Semis are still doing more than their share of the work.')
if dbc is not None and dbc > 0.8:
    regime.append('Commodity strength keeps the copper/reflation sleeve relevant.')
summary = regime[0] if regime else 'No dominant macro regime is obvious, so theme selection matters more than market narration.'

rows = {sym: (quotes.get(sym) or {}) for sym in stooq_map}

def avg_change(symbols):
    vals = [rows[s].get('chg') for s in symbols if rows.get(s) and rows[s].get('chg') is not None]
    if not vals:
        return None
    return sum(vals) / len(vals)

def theme_read(name, symbols):
    avg = avg_change(symbols)
    if avg is None:
        return None
    if name == 'AI / Semis':
        if avg <= -2:
            return f'{name} is weak enough to ask whether AI leadership is narrowing rather than broadening.'
        if avg >= 2:
            return f'{name} still looks sponsored; the market is not done paying for AI exposure.'
    if name == 'Software / Cyber / Infra':
        if avg <= -2:
            return f'{name} looks unforgiving, which usually means investors want cleaner proof before paying up.'
        if avg >= 2:
            return f'{name} is acting like quality software is still being accumulated, not just admired.'
    if name == 'AI Infrastructure / Power / Datacenter':
        if avg <= -2:
            return f'{name} is cooling, which would matter because it is one of the cleaner second-derivative AI expressions.'
        if avg >= 2:
            return f'{name} is still validating the buildout trade beyond obvious chip winners.'
    if name == 'Consumer / Commerce Platforms':
        if avg <= -2:
            return f'{name} is soft, which can mean the market is getting pickier on consumer/platform duration.'
        if avg >= 2:
            return f'{name} is holding up, which is constructive for long-duration consumer/platform exposure.'
    if name == 'Commodities / Reflation':
        if avg <= -2:
            return f'{name} is weak, so the market is not paying for reflation or copper torque right now.'
        if avg >= 2:
            return f'{name} is working, which says cyclicals and hard-asset leverage still have a pulse.'
    if name == 'International / Special Situations':
        return f'{name} should be read more through idiosyncratic risk and sizing than broad market mood.'
    return None

theme_lines = []
for name, symbols in themes.items():
    line = theme_read(name, symbols)
    if line:
        theme_lines.append((name, line, avg_change(symbols)))

def major_name_moves():
    out = []
    for sym, q in rows.items():
        chg = q.get('chg')
        if chg is None:
            continue
        if abs(chg) >= 4.5:
            out.append((abs(chg), sym, q))
    out.sort(reverse=True)
    return out[:4]

major = major_name_moves()

print('<section class="card">')
print('<h2>Market Intelligence</h2>')
print('<p><strong>What matters:</strong> ' + esc(summary) + '</p>')
print('<ul>')
for line in regime[1:3]:
    print('<li>' + esc(line) + '</li>')
for _, line, _ in theme_lines[:2]:
    print('<li>' + esc(line) + '</li>')
if len(regime) == 0 and len(theme_lines) == 0:
    print('<li>The right default is patience: no regime shift, no need to manufacture one.</li>')
print('</ul>')
print('<h3>Invested Themes</h3>')
print('<ul>')
shown = 0
for name, line, avg in sorted(theme_lines, key=lambda x: abs(x[2]) if x[2] is not None else 0, reverse=True):
    if avg is None or abs(avg) < 1.5:
        continue
    print(f'<li><strong>{esc(name)}</strong> ({esc(fmt_pct(avg))}) — {esc(line)}</li>')
    shown += 1
    if shown >= 5:
        break
if shown == 0:
    print('<li>No invested theme is moving enough to matter; that is usually a sign to focus on thesis, not tape noise.</li>')
print('</ul>')
print('<h3>Only Moves Big Enough to Matter</h3>')
print('<ul>')
if major:
    for _, sym, q in major:
        print(f'<li><strong>{esc(sym)}</strong> {esc(fmt_price(q.get("price")))} ({esc(fmt_pct(q.get("chg")))}) — worth checking only if the move is tied to real news or thesis change.</li>')
else:
    print('<li>No name in your watchlist is moving enough to deserve attention on price action alone.</li>')
print('</ul>')
print('<h3>Crypto</h3>')
print('<ul>')
for sym in crypto_syms:
    item = crypto.get(sym)
    if item:
        note = 'worth attention only if tied to a thesis or market-structure shift.' if abs(item.get('chg') or 0) >= 4 else 'mostly noise unless the move extends or the thesis changes.'
        print(f'<li><strong>{sym}</strong> {esc(fmt_price(item.get("price")))} ({esc(fmt_pct(item.get("chg")))}) — {esc(note)}</li>')
if not crypto:
    print('<li class="muted">Crypto feed unavailable.</li>')
print('</ul>')
print('</section>')
print('__SUMMARY__' + summary)
PY

echo "__FETCHED_AT__${FETCHED_AT}"
