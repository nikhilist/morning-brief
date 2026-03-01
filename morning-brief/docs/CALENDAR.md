# Google Calendar Integration

This document describes the Google Calendar integration for the Morning Brief dashboard.

## Features

- **Today's Schedule**: View all events for today with time, duration, location, and video call links
- **Tomorrow's Preview**: See what's coming up tomorrow
- **Live Status**: Events happening now are highlighted in green
- **Quick Join**: One-click access to Google Meet/Zoom links
- **Dark/Light Mode**: Fully styled for both themes
- **Error Handling**: Graceful fallback when not authenticated

## Setup Instructions

### 1. Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the **Google Calendar API**:
   - Navigate to "APIs & Services" > "Library"
   - Search for "Google Calendar API"
   - Click "Enable"

### 2. OAuth 2.0 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Configure the consent screen:
   - User Type: External
   - App name: "Morning Brief"
   - User support email: Your email
   - Developer contact: Your email
4. Create OAuth client ID:
   - Application type: Web application
   - Name: "Morning Brief Web"
   - Authorized redirect URIs:
     - `http://localhost:3000/api/auth/google/callback` (for local dev)
     - `https://yourdomain.com/api/auth/google/callback` (for production)
5. Copy the **Client ID** and **Client Secret**

### 3. Environment Variables

Add these to your `.env.local`:

```env
GOOGLE_CLIENT_ID=your_client_id_here
GOOGLE_CLIENT_SECRET=your_client_secret_here
GOOGLE_REDIRECT_URI=http://localhost:3000/api/auth/google/callback
```

### 4. Authentication

1. Start the dev server: `npm run dev`
2. Go to the Morning Brief dashboard
3. Click "Connect Google Calendar"
4. Sign in with your Google account and grant permissions
5. After redirect, copy the `refresh_token` from the response
6. Add it to `.env.local`:
   ```env
   GOOGLE_REFRESH_TOKEN=your_refresh_token_here
   ```
7. Restart the server

## Architecture

### Files

- `lib/calendar.ts` - Core calendar service with Google API integration
- `pages/api/calendar/auth.ts` - Returns OAuth URL for authentication
- `pages/api/auth/google/callback.ts` - OAuth callback handler
- `pages/api/briefing.ts` - Updated to include calendar data in briefing
- `pages/index.tsx` - Dashboard UI with CalendarSection component

### Data Flow

1. Dashboard requests briefing data from `/api/briefing`
2. `fetchCalendarEvents()` checks for credentials
3. If not connected, returns `connected: false` with error message
4. If connected, fetches today's and tomorrow's events from Google Calendar API
5. Events are parsed and formatted for display
6. Dashboard shows either calendar view or "Connect" prompt

### API Endpoints

- `GET /api/calendar/auth` - Returns OAuth URL for connecting calendar
- `GET /api/auth/google/callback?code=xxx` - OAuth callback (returns tokens)
- `GET /api/briefing` - Returns full briefing including calendar data

### Calendar Data Structure

```typescript
interface CalendarData {
  today: {
    date: string;
    dayName: string;
    events: CalendarEvent[];
  };
  tomorrow: {
    date: string;
    dayName: string;
    events: CalendarEvent[];
  };
  connected: boolean;
  error?: string;
}

interface CalendarEvent {
  id: string;
  title: string;
  start: string;  // ISO date string
  end: string;    // ISO date string
  duration: number; // minutes
  location?: string;
  meetLink?: string;  // Google Meet/Zoom URL
  description?: string;
  organizer?: string;
  attendees?: string[];
  isAllDay: boolean;
  status: string;
}
```

## UI Components

### CalendarSection
Main section component that handles:
- Connected/not connected states
- Authentication flow
- Grid layout for today/tomorrow
- Event count badges

### EventCard
Individual event display showing:
- Title (truncated with tooltip)
- Time range and duration
- "NOW" badge for current events
- Location with icon
- Attendee count
- Join button for video calls

## Styling

### Dark Mode
- Background: `bg-slate-800`
- Event cards: `bg-slate-700/50` with `border-blue-500`
- Current events: `bg-green-900/20` with `border-green-500`
- Text: `text-white`, `text-gray-400`

### Light Mode
- Background: `bg-white`
- Event cards: `bg-gray-100` with `border-blue-500`
- Current events: `bg-green-50` with `border-green-500`
- Text: `text-gray-900`, `text-gray-600`

## Error Handling

The integration handles several error scenarios:

1. **Not Configured**: Missing GOOGLE_CLIENT_ID/GOOGLE_CLIENT_SECRET
   - Shows "Connect Calendar" button
   - Button click returns config error

2. **Not Authenticated**: No refresh token
   - Shows "Connect Calendar" prompt
   - OAuth flow initiates on click

3. **Auth Expired**: Invalid/expired refresh token
   - Returns 401-style error
   - Prompts user to reconnect

4. **API Errors**: Google API failures
   - Returns error message
   - Doesn't crash the dashboard

## Security Notes

- Never commit `.env.local` to git
- Refresh tokens are sensitive - store securely
- The app only requests `calendar.readonly` scope
- Tokens can be revoked from Google Account settings

## Troubleshooting

### "Connect Calendar" button doesn't work
- Check that GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET are set
- Verify redirect URI matches exactly in Google Console

### Events not showing after connecting
- Check server logs for API errors
- Verify GOOGLE_REFRESH_TOKEN is set correctly
- Try refreshing the page

### Token expired errors
- Re-run the OAuth flow
- Update GOOGLE_REFRESH_TOKEN in env

## Future Enhancements

- [ ] Multi-calendar support (select which calendars to show)
- [ ] All-day event styling improvements
- [ ] Recurring event indicators
- [ ] Event reminders/notifications
- [ ] Direct calendar editing
- [ ] Week view option
