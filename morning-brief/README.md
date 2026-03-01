# 🌅 Morning Brief Dashboard

An AI-powered personal morning briefing system with real-time data, smart insights, and beautiful UI.

![Dashboard Preview](https://nik-sites.vercel.app/dashboard)

## ✨ Features

### Core Sections
- **☁️ Weather** - Live conditions + 3-day forecast for Princeton, NJ
- **🗓️ Schedule** - Calendar integration (configurable)
- **⚽ Arsenal FC** - Live match updates, injuries, team news
- **🪙 Crypto Markets** - BTC, ETH, SOL prices + sentiment analysis
- **💻 Hacker News** - Top tech stories
- **🔥 Viral Pulse** - Real-time X/Twitter trends
- **🧠 AI Life Strategy** - Personalized daily focus, blindspots, pattern analysis

### Smart Features
- 🌙 Dark/Light mode toggle
- 📱 Mobile-first responsive design
- 🔄 Auto-refresh every 5 minutes
- 🎯 AI-generated insights based on your patterns
- 📤 Optional Telegram notifications
- ⏰ Daily 5 AM auto-generation (Vercel Cron)

## 🚀 Quick Deploy to Vercel

### Option 1: One-Click Deploy
[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/yourusername/morning-brief)

### Option 2: Manual Deploy

1. **Install Vercel CLI:**
```bash
npm i -g vercel
```

2. **Deploy:**
```bash
cd morning-brief
vercel --prod
```

3. **Set Environment Variables:**
   - Go to Vercel Dashboard → Project Settings → Environment Variables
   - Add: `BRAVE_API_KEY` = `BSABaujKs3mlDim6ZDVciOo9nNbDCh8`
   - Optional: Add Telegram tokens for notifications

4. **Redeploy:**
```bash
vercel --prod
```

## ⚙️ Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `BRAVE_API_KEY` | ✅ Yes | For news/search data |
| `TELEGRAM_BOT_TOKEN` | ❌ No | Send briefings to Telegram |
| `TELEGRAM_CHAT_ID` | ❌ No | Your Telegram chat ID |
| `CRON_SECRET` | ❌ No | Secure cron endpoint |

## 🔧 Customization

### Change Location
Edit `pages/api/briefing.ts` - search for "Princeton,NJ" and replace with your city.

### Add Calendar
1. Set up Google Calendar API
2. Add credentials to env vars
3. Uncomment calendar code in `briefing.ts`

### Change Arsenal to Your Team
Search for Arsenal-related code in `briefing.ts` and modify queries.

### Add Stocks/Portfolio
Add a new API route and card component for stock data.

## 🎨 Design System

- **Primary:** Arsenal Red (`#EF0107`)
- **Background:** Slate-900 (dark) / Gray-50 (light)
- **Cards:** Rounded-2xl with subtle shadows
- **Font:** System default (Inter on Vercel)

## 📁 Project Structure

```
morning-brief/
├── pages/
│   ├── index.tsx          # Main dashboard UI
│   ├── _app.tsx           # App wrapper
│   └── api/
│       ├── briefing.ts    # Main data API
│       └── cron/
│           └── generate.ts # 5 AM cron job
├── styles/
│   └── globals.css        # Tailwind + custom styles
├── public/                # Static assets
├── vercel.json           # Cron config
└── package.json
```

## 🔄 Cron Job

The briefing regenerates daily at **5:00 AM ET** via Vercel Cron.

Manual trigger:
```bash
curl https://your-site.vercel.app/api/cron/generate?secret=YOUR_CRON_SECRET
```

## 📝 License

MIT - Customize it, make it yours!

---

**Built with:** Next.js • Tailwind • TypeScript • Vercel • Brave Search • OpenClaw AI
