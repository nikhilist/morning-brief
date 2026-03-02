import type { NextApiRequest, NextApiResponse } from 'next';

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
  isAllDay: boolean;
  status: string;
}

function addDays(date: Date, days: number): Date {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

function startOfDay(date: Date): Date {
  const result = new Date(date);
  result.setHours(0, 0, 0, 0);
  return result;
}

function endOfDay(date: Date): Date {
  const result = new Date(date);
  result.setHours(23, 59, 59, 999);
  return result;
}

function formatISO(date: Date): string {
  return date.toISOString();
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { access_token } = req.query;
  const today = new Date();

  if (!access_token || typeof access_token !== 'string') {
    return res.status(401).json({
      connected: false,
      error: 'Not authenticated',
      today: { date: today.toISOString(), dayName: 'Today', events: [] },
      tomorrow: { date: addDays(today, 1).toISOString(), dayName: 'Tomorrow', events: [] }
    });
  }

  try {
    const tomorrow = addDays(today, 1);

    // Fetch today's events
    const todayParams = new URLSearchParams({
      calendarId: 'primary',
      timeMin: formatISO(startOfDay(today)),
      timeMax: formatISO(endOfDay(today)),
      singleEvents: 'true',
      orderBy: 'startTime',
      maxResults: '20',
    });

    const todayRes = await fetch(`https://www.googleapis.com/calendar/v3/calendars/primary/events?${todayParams}`, {
      headers: { Authorization: `Bearer ${access_token}` }
    });

    if (!todayRes.ok) {
      const error = await todayRes.json();
      throw new Error(error.error?.message || 'Failed to fetch today\'s events');
    }

    const todayData = await todayRes.json();

    // Fetch tomorrow's events
    const tomorrowParams = new URLSearchParams({
      calendarId: 'primary',
      timeMin: formatISO(startOfDay(tomorrow)),
      timeMax: formatISO(endOfDay(tomorrow)),
      singleEvents: 'true',
      orderBy: 'startTime',
      maxResults: '20',
    });

    const tomorrowRes = await fetch(`https://www.googleapis.com/calendar/v3/calendars/primary/events?${tomorrowParams}`, {
      headers: { Authorization: `Bearer ${access_token}` }
    });

    if (!tomorrowRes.ok) {
      const error = await tomorrowRes.json();
      throw new Error(error.error?.message || 'Failed to fetch tomorrow\'s events');
    }

    const tomorrowData = await tomorrowRes.json();

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
        isAllDay,
        status: event.status,
      };
    };

    const todayEvents = (todayData.items || []).map(mapEvent);
    const tomorrowEvents = (tomorrowData.items || []).map(mapEvent);

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
