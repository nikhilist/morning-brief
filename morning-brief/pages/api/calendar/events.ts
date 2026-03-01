import type { NextApiRequest, NextApiResponse } from 'next';
import { google } from 'googleapis';
import { addDays, startOfDay, endOfDay, formatISO } from 'date-fns';

const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;

interface CalendarEvent {
  id: string;
  title: string;
  start: string;
  end: string;
  duration: number;
  location?: string;
  meetLink?: string;
  description?: string;
  organizer?: string;
  attendees?: string[];
  isAllDay: boolean;
  status: string;
}

interface CalendarDay {
  date: string;
  dayName: string;
  events: CalendarEvent[];
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { access_token, refresh_token } = req.query;
  const today = new Date();

  if (!access_token || typeof access_token !== 'string') {
    return res.status(401).json({
      connected: false,
      error: 'Not authenticated',
      today: { date: today.toISOString(), dayName: 'Today', events: [] },
      tomorrow: { date: addDays(today, 1).toISOString(), dayName: 'Tomorrow', events: [] }
    });
  }

  if (!GOOGLE_CLIENT_ID || !GOOGLE_CLIENT_SECRET) {
    return res.status(500).json({
      connected: false,
      error: 'Calendar not configured on server',
      today: { date: today.toISOString(), dayName: 'Today', events: [] },
      tomorrow: { date: addDays(today, 1).toISOString(), dayName: 'Tomorrow', events: [] }
    });
  }

  try {
    const oauth2Client = new google.auth.OAuth2(
      GOOGLE_CLIENT_ID,
      GOOGLE_CLIENT_SECRET
    );

    oauth2Client.setCredentials({
      access_token,
      refresh_token: refresh_token as string | undefined,
    });

    const calendar = google.calendar({ version: 'v3', auth: oauth2Client });

    const tomorrow = addDays(today, 1);

    // Fetch today's events
    const todayRes = await calendar.events.list({
      calendarId: 'primary',
      timeMin: formatISO(startOfDay(today)),
      timeMax: formatISO(endOfDay(today)),
      singleEvents: true,
      orderBy: 'startTime',
      maxResults: 20,
    });

    // Fetch tomorrow's events
    const tomorrowRes = await calendar.events.list({
      calendarId: 'primary',
      timeMin: formatISO(startOfDay(tomorrow)),
      timeMax: formatISO(endOfDay(tomorrow)),
      singleEvents: true,
      orderBy: 'startTime',
      maxResults: 20,
    });

    const mapEvent = (event: any): CalendarEvent => {
      const start = event.start?.dateTime || event.start?.date;
      const end = event.end?.dateTime || event.end?.date;
      const isAllDay = !event.start?.dateTime;

      // Extract Meet link from various sources
      let meetLink = event.hangoutLink;
      if (!meetLink && event.conferenceData?.entryPoints) {
        const videoEntry = event.conferenceData.entryPoints.find((e: any) => e.entryPointType === 'video');
        meetLink = videoEntry?.uri;
      }
      if (!meetLink && event.location?.includes('meet.google.com')) {
        meetLink = event.location;
      }
      if (!meetLink && event.description) {
        const meetMatch = event.description.match(/https:\/\/meet\.google\.com\/[a-z-]+/i);
        if (meetMatch) meetLink = meetMatch[0];
      }

      return {
        id: event.id,
        title: event.summary || 'Untitled',
        start,
        end,
        duration: isAllDay ? 0 : Math.round((new Date(end).getTime() - new Date(start).getTime()) / 60000),
        location: event.location,
        meetLink,
        description: event.description,
        organizer: event.organizer?.displayName || event.organizer?.email,
        attendees: event.attendees?.map((a: any) => a.displayName || a.email) || [],
        isAllDay,
        status: event.status,
      };
    };

    const todayEvents = (todayRes.data.items || []).map(mapEvent);
    const tomorrowEvents = (tomorrowRes.data.items || []).map(mapEvent);

    res.status(200).json({
      connected: true,
      today: {
        date: today.toISOString(),
        dayName: 'Today',
        events: todayEvents,
      },
      tomorrow: {
        date: tomorrow.toISOString(),
        dayName: 'Tomorrow',
        events: tomorrowEvents,
      },
    });
  } catch (error: any) {
    console.error('Calendar fetch error:', error);
    res.status(500).json({
      connected: false,
      error: error.message || 'Failed to fetch calendar',
      today: { date: today.toISOString(), dayName: 'Today', events: [] },
      tomorrow: { date: addDays(today, 1).toISOString(), dayName: 'Tomorrow', events: [] }
    });
  }
}
