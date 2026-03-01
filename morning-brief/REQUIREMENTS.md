# Morning Brief Dashboard - Technical Requirements Specification

**Version:** 2.4.0  
**Last Updated:** February 23, 2026  
**Deployed URL:** https://morning-brief-nine.vercel.app

---

## 1. Overview

The Morning Brief is an automated, AI-powered personal briefing system that aggregates and analyzes data from multiple sources to provide a comprehensive morning briefing. The dashboard refreshes automatically at 5 AM daily and includes manual refresh functionality.

**Core Philosophy:** High signal-to-noise ratio. Insights over raw data. Actionable intelligence over information overload.

---

## 2. Technical Architecture

### 2.1 Stack
- **Frontend:** Next.js 14, React, TypeScript, Tailwind CSS
- **Backend:** Next.js API Routes (serverless)
- **Deployment:** Vercel
- **Data Sources:** Multiple APIs (see per-section details)

### 2.2 Data Flow
1. User loads dashboard → API fetches fresh data from all sources
2. Data processed and insights generated server-side
3. Client receives structured JSON, renders components
4. Auto-refresh every 5 minutes; manual refresh available

---

## 3. Section Specifications

### 3.1 Weather — Princeton, NJ

**Purpose:** Provide location-specific weather with AI-generated strategic insights for daily planning.

**Data Source:** wttr.in (free, no API key required)
- Endpoint: `https://wttr.in/Princeton,NJ?format=j1`
- Updates: Real-time on each request

**Features:**
- Current temperature, condition, high/low
- Humidity, wind speed, precipitation chance
- 3-day forecast with day names

**AI Insights Generated:**
- **Immediate:** Current conditions with "feels like" context
- **Today's Strategy:** Activity recommendations based on precip chance
- **Tomorrow's Setup:** Preparation guidance for next day

**UI:**
- Large temperature display (text-6xl)
- Grid layout: Current conditions left, insights right
- Color-coded insight boxes (blue, yellow, green)

**Known Limitations:**
- Fixed location (Princeton, NJ) - user-configurable in future
- No severe weather alerts

---

### 3.2 Arsenal FC

**Purpose:** Comprehensive Arsenal coverage including results, fixtures, injuries, news, and league position.

**Data Sources:**
- **Primary:** Brave Search API (news search)
  - Latest results: `Arsenal FC latest result match`
  - Fixtures: `Arsenal FC fixtures 2026`
  - News: `Arsenal FC latest news`
- **Table:** Currently static (requires football-data.org integration)

**Features:**
1. **Last Match Result**
   - Score extraction from news headlines
   - Pattern matching: `2-1`, `WIN`, `LOSS`, `DRAW`
   - Opponent extraction
   - Clickable link to full report

2. **Upcoming Fixtures (Next 3)**
   - Opponent name, date, competition
   - Sourced from web search

3. **Injury Room**
   - Player name, status (FIT/DOUBT/OUT), notes
   - Color-coded status badges
   - Static fallback if API fails

4. **Trending News (Top 3)**
   - Latest Arsenal headlines
   - Source attribution
   - Clickable links

5. **Premier League Table (Top 3)**
   - Position, Team, Played (P), Won (W), Points (Pts), Form
   - Highlight Arsenal row
   - **CURRENTLY STATIC** — needs football-data.org API

**UI:**
- Last result: Large prominent display with big score
- 3-column grid for fixtures, injuries, news
- Full-width table below

**Known Limitations:**
- Premier League table is hardcoded (needs sports data API)
- Fixture dates may be imprecise from web search
- Injury data uses static fallback

**Future Improvements:**
- Integrate football-data.org (free tier: 10 calls/min)
- Add match statistics (shots, possession, xG)
- Player ratings from WhoScored

---

### 3.3 Crypto Markets

**Purpose:** Cryptocurrency prices, market sentiment, and contrarian analysis.

**Data Source:** CoinGecko API (free, no key required)
- Endpoint: `/simple/price` with 24h change
- Coins: Bitcoin, Ethereum, Solana

**Features:**
1. **Price Display**
   - Current price (USD)
   - 24h change percentage
   - Up/down indicators (green/red)

2. **Market Metrics**
   - BTC Dominance
   - Fear & Greed Index (estimated from price action)

3. **AI Insights**
   - **Macro Context:** Market conditions analysis
   - **Smart Money Signals:** Whale behavior, exchange outflows
   - **Contrarian Setup:** Fear/greed dynamics, entry opportunities

**UI:**
- Price cards with large numbers
- Insight boxes with strategic analysis
- Color-coded for readability

**Known Limitations:**
- Fear & Greed is estimated, not from official index
- Limited to 3 coins (BTC, ETH, SOL)

**Future Improvements:**
- Add Fear & Greed Index API
- Portfolio tracking
- Price alerts

---

### 3.4 Traditional Markets (Tradfi)

**Purpose:** Macro context for equity and traditional markets.

**Data Source:** Static insights (no real-time market data currently)

**Features:**
1. **Macro Context**
   - Fed policy outlook
   - Tariff/SCOTUS impact
   - AI capex cycle status
   - Market rotation observations

2. **Key Themes**
   - AI Infrastructure (NVDA, ALAB, VRT)
   - Cybersecurity (CRWD, NBIS)
   - Impact ratings (Massive/High/Medium)

**UI:**
- Two-column layout
- Card-based theme display
- Color-coded impact badges

**Known Limitations:**
- No live market prices
- No portfolio tracking
- Static content

**Future Improvements:**
- Yahoo Finance API for real-time quotes
- Your watchlist: NBIS, CRWD, RBRK, DOCN, NOW, ALAB, JMIA, MELI, VRT, NVDA, AMAT, AMZN, SITM, COPX
- Market open/close indicators

---

### 3.5 Reddit Radar — Your Communities

**Purpose:** Aggregate hot posts from user's subscribed subreddits.

**Data Source:** Reddit API (public, no auth required)
- Endpoint: `/r/{subreddit}/hot.json`
- Subreddits: memes, soccer, Gunners, frugalmalefashion, malefashionadvice, wallstreetbets, technology, india

**Features:**
- Top 2 posts per subreddit
- Upvotes and comment counts
- Clickable links to Reddit
- Community-specific display

**UI:**
- 2-column grid layout
- Subreddit name with alien icon
- Post cards with engagement metrics

**Known Limitations:**
- Reddit rate limiting (may return empty if hit)
- Only 8 configured subreddits
- No user authentication (can't see subscribed, just configured)

**Future Improvements:**
- User-configurable subreddit list
- Reddit OAuth for personalized feed
- Comment preview

---

### 3.6 Bluesky — Your Feed

**Purpose:** Display user's Bluesky timeline and network stats.

**Data Source:** Bluesky API (public)
- Handle: nikhilist.bsky.social
- Profile info: follows count

**Features:**
- Connected handle display
- Follows count (351 accounts)
- Link to personal timeline
- Link to follows list

**UI:**
- Profile card with stats
- "View Timeline" CTA button
- Clean, minimal design

**Known Limitations:**
- Bluesky timeline requires authentication (API limitation)
- Cannot show actual feed without user login
- Shows network stats only

**Future Improvements:**
- Bluesky OAuth integration
- Timeline display
- Trend analysis from follows

---

### 3.7 Viral Pulse — What's Breaking the Internet

**Purpose:** Fun/viral content discovery across social platforms.

**Data Source:** Brave Search API
- Queries: memes, TikTok trending, viral moments, X/Twitter

**Features:**
- 4 categories: Memes, TikTok, Viral Moments, X/Twitter
- Headlines with platform tags
- Clickable links to source
- Fun/emotional tone (different from serious sections)

**UI:**
- Color-coded cards (purple, pink, blue, yellow)
- Emoji icons
- Linkable headlines

**Known Limitations:**
- Links may redirect to search pages if direct URL unavailable
- Content quality varies by search results

**Future Improvements:**
- Reddit API for actual trending memes
- TikTok API (requires auth)
- YouTube trending integration

---

### 3.8 AI Life Strategy & Analysis

**Purpose:** Synthesize all data into actionable daily guidance.

**Data Sources:** All previous sections combined
- Weather, crypto trends, Reddit activity, Arsenal news, calendar day

**AI-Generated Insights:**

1. **Strategic Assessment**
   - Market condition summary
   - Emotional state recommendations
   - Priority setting

2. **Blindspots**
   - Weather impact underestimation
   - Crypto FOMO/fear patterns
   - Arsenal emotional investment
   - Reddit echo chamber warning

3. **Opportunities**
   - Family time windows
   - DCA opportunities in crypto
   - Deep work blocks
   - Week preparation

4. **Tactical Moves**
   - Price alerts
   - Calendar blocking
   - Communication tasks
   - Match prep

5. **Pattern Analysis**
   - Weekend rhythm recognition
   - Decision-making patterns
   - Emotional triggers

**UI:**
- Large strategic assessment box (full width)
- 2-column grid for blindspots/opportunities
- Full-width pattern analysis

**Known Limitations:**
- Insights are rule-based templates, not true AI
- No personal historical data (would need user tracking)

**Future Improvements:**
- True LLM integration for dynamic insights
- Personal pattern learning over time
- Integration with calendar for specific conflicts

---

## 4. Global Features

### 4.1 Auto-Refresh
- **Cron Schedule:** Daily at 5:00 AM UTC
- **Vercel Cron:** Configured in vercel.json
- **Client-Side:** Every 5 minutes while page open

### 4.2 Manual Refresh
- Floating action button (bottom-right)
- Loading spinner during refresh
- Immediate data re-fetch

### 4.3 Dark/Light Mode
- Toggle button in header
- Persistent per session
- CSS variables for theming

### 4.4 Mobile Responsive
- Single column on mobile
- Stacked layout for complex sections
- Touch-friendly buttons

---

## 5. Data Sources & API Keys

| Source | API Key Required | Cost | Reliability |
|--------|-----------------|------|-------------|
| wttr.in (Weather) | No | Free | High |
| CoinGecko (Crypto) | No | Free | High |
| Brave Search | Yes (stored in Vercel) | Free tier | Medium |
| Reddit | No | Free | Medium (rate limits) |
| Bluesky | No | Free | High |

**Environment Variables:**
- `BRAVE_API_KEY` — Required for news/search features

---

## 6. Known Issues & Technical Debt

### 6.1 Current Issues
1. **Arsenal Table:** Hardcoded data — needs football-data.org integration
2. **Arsenal Fixtures:** Imprecise dates from web search
3. **Reddit:** Occasional rate limiting returns empty results
4. **Bluesky Timeline:** Cannot access without user authentication

### 6.2 Technical Debt
- Mixed sync/async patterns in API routes
- Error handling could be more granular
- No caching layer (every request hits APIs)
- No retry logic for failed API calls

---

## 7. Future Roadmap

### 7.1 High Priority
- [ ] football-data.org integration for live PL table
- [ ] User-configurable location (not just Princeton)
- [ ] Add calendar integration (Google/Outlook)
- [ ] True LLM for AI Strategy section

### 7.2 Medium Priority
- [ ] Portfolio tracking for stocks/crypto
- [ ] Email delivery option (morning brief to inbox)
- [ ] Telegram bot for alerts
- [ ] Historical data tracking

### 7.3 Nice to Have
- [ ] Voice narration (TTS)
- [ ] PWA for mobile app experience
- [ ] Custom theme builder
- [ ] Multiple briefing profiles (work/weekend/travel)

---

## 8. Maintenance

### 8.1 Monitoring
- Vercel Analytics for usage
- API error logs in Vercel dashboard
- Manual testing of refresh button

### 8.2 API Key Rotation
- Brave Search: Check usage monthly
- Rotate if approaching limits
- Update in Vercel dashboard, redeploy

### 8.3 Backup
- Code in workspace folder: `~/.openclaw/workspace/morning-brief/`
- Vercel Git integration for version history

---

**Document Owner:** Gunner (AI Assistant)  
**Review Cycle:** Monthly or after major feature additions