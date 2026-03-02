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
  calendarName: string;
  calendarAccess: string;
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

async function fetchCalendarList(accessToken: string): Promise<Array<{ id: string; name: string; accessRole: string }>> {
  try {
    // Include all calendars (primary + shared + subscribed)
    const res = await fetch('https://www.googleapis.com/calendar/v3/users/me/calendarList?showHidden=true&showDeleted=false', {
      headers: { Authorization: `Bearer ${accessToken}` }
    });

    if (!res.ok) {
      console.error('Failed to fetch calendar list');
      return [{ id: 'primary', name: 'My Calendar', accessRole: 'owner' }];
    }

    const data = await res.json();
    console.log(`Found ${data.items?.length || 0} calendars:`, data.items?.map((c: any) => ({ name: c.summary, access: c.accessRole, selected: c.selected })));
    
    // Include all calendars the user has access to (not just selected ones)
    // This includes shared family calendars
    return (data.items || [])
      .filter((cal: any) => {
        // Include if user has read access (owner, writer, or reader)
        const hasAccess = ['owner', 'writer', 'reader'].includes(cal.accessRole);
        return hasAccess;
      })
      .map((cal: any) => ({ 
        id: cal.id, 
        name: cal.summary,
        accessRole: cal.accessRole
      }));
  } catch (e) {
    console.error('Calendar list fetch error:', e);
    return [{ id: 'primary', name: 'My Calendar', accessRole: 'owner' }];
  }
}

async function fetchEventsForCalendar(
  accessToken: string, 
  calendarId: string, 
  timeMin: string, 
  timeMax: string
): Promise<any[]> {
  try {
    const params = new URLSearchParams({
      timeMin,
      timeMax,
      singleEvents: 'true',
      orderBy: 'startTime',
      maxResults: '50',
    });

    // URL encode calendar ID in case it contains special characters
    const encodedCalendarId = encodeURIComponent(calendarId);
    const url = `https://www.googleapis.com/calendar/v3/calendars/${encodedCalendarId}/events?${params}`;

    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${accessToken}` }
    });

    if (!res.ok) {
      const error = await res.json();
      console.error(`Failed to fetch events for calendar ${calendarId}:`, error);
      return [];
    }

    const data = await res.json();
    return data.items || [];
  } catch (e) {
    console.error(`Events fetch error for ${calendarId}:`, e);
    return [];
  }
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
    const todayStart = formatISO(startOfDay(today));
    const todayEnd = formatISO(endOfDay(today));
    const tomorrowStart = formatISO(startOfDay(tomorrow));
    const tomorrowEnd = formatISO(endOfDay(tomorrow));

    // Get all calendars (primary + shared)
    const calendars = await fetchCalendarList(access_token);
    console.log(`Found ${calendars.length} calendars:`, calendars.map(c => c.name));

    // Fetch events from all calendars
    let allTodayEvents: CalendarEvent[] = [];
    let allTomorrowEvents: CalendarEvent[] = [];

    for (const calendar of calendars) {
      // Today's events
      const todayEvents = await fetchEventsForCalendar(
        access_token, 
        calendar.id, 
        todayStart, 
        todayEnd
      );

      // Tomorrow's events
      const tomorrowEvents = await fetchEventsForCalendar(
        access_token, 
        calendar.id, 
        tomorrowStart, 
        tomorrowEnd
      );

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
          calendarName: calendar.name,
          calendarAccess: calendar.accessRole,
          isAllDay,
          status: event.status,
        };
      };

      allTodayEvents = allTodayEvents.concat(todayEvents.map(mapEvent));
      allTomorrowEvents = allTomorrowEvents.concat(tomorrowEvents.map(mapEvent));
    }

    // Sort events by start time
    allTodayEvents.sort((a, b) => new Date(a.start).getTime() - new Date(b.start).getTime());
    allTomorrowEvents.sort((a, b) => new Date(a.start).getTime() - new Date(b.start).getTime());

    res.status(200).json({
      connected: true,
      calendars: calendars.map(c => c.name),
      today: {
        date: today.toISOString(),
        dayName: 'Today',
        events: allTodayEvents,
      },
      tomorrow: {
        date: tomorrow.toISOString(),
        dayName: 'Tomorrow',
        events: allTomorrowEvents,
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
