# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod

## Configurations — DO NOT DELETE

### Daily Briefs (3x daily) — EDT Schedule
- **Morning Brief** — 8:00 AM EDT (12:00 PM UTC)
  - Cron ID: `59aea0cd-f3da-4556-b0f8-b5da9e8dd866`
  - Full brief: weather, both calendars, all unread emails, tasks, habits, Arsenal news
  
- **Afternoon Brief** — 4:00 PM EDT (8:00 PM UTC)
  - Cron ID: `e01cd07b-d98b-4d92-bc22-5c73b3dfa0f3`
  - Update: what's changed since morning
  
- **Evening Brief** — 10:00 PM EDT (2:00 AM UTC next day)
  - Cron ID: `939d9e12-4519-4667-8edd-b0bff4fb41a8`
  - Insights: day review, patterns, tomorrow prep
  - **Habit Streaks:** Shows current streak for all habits (only in evening brief)

- **Telegram Delivery**: @Nikhoshi (chat ID: 935335162)
- **GitHub Pages Dashboard**: https://nikhilist.github.io/morning-brief/
  - Auto-deploys with each brief
  - Mobile-friendly dark theme
  - Public URL, works from anywhere
- **Script**: `~/.openclaw/workspace/generate-brief-html.sh`

### Google OAuth (gog)
- Email: nikhilist@gmail.com
- Services: Gmail, Calendar, Drive
- Client secret: `~/.openclaw/credentials/google_client_secret.json`
- Token storage: `~/.config/gogcli/keyring/`
- Binary: `~/.local/bin/gog`
- Env vars needed:
  - `GOG_KEYRING_BACKEND=file`
  - `GOG_KEYRING_PASSWORD=""`
  - `GOG_ACCOUNT=nikhilist@gmail.com`

### Todoist
- API Token: `81d341953323302cf0919e4ec8a8d9531ea6f881`
- CLI: `todoist` (npm: `todoist-ts-cli`)
- Config: `~/.config/todoist-cli/config.json`

### Habitica
- User ID: `404a4487-6eea-4ed3-b60b-03f82092b29a`
- API Token: `e3470ee9-56d7-49f4-bd56-4f3f175bd804`
- Config: `~/.habitica`
- Skill: `~/.openclaw/workspace/skills/habitica-skill/`

### Telegram
- Bot connected: YES
- Username: @Nikhoshi
- Chat ID: 935335162
- Used for: Morning brief delivery

### Arsenal News
- Source: https://arseblog.news/
- Format: Summarize all articles from last 24h
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.
