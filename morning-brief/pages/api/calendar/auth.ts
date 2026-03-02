import type { NextApiRequest, NextApiResponse } from 'next';

const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;
const REDIRECT_URI = process.env.GOOGLE_REDIRECT_URI || 'https://morning-brief-nine.vercel.app/api/calendar/callback';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  console.log('Calendar auth called');
  console.log('Client ID exists:', !!GOOGLE_CLIENT_ID);
  console.log('Client Secret exists:', !!GOOGLE_CLIENT_SECRET);
  console.log('Redirect URI:', REDIRECT_URI);

  if (!GOOGLE_CLIENT_ID || !GOOGLE_CLIENT_SECRET) {
    return res.status(500).json({ 
      error: 'Calendar not configured',
      details: 'GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET must be set in environment variables'
    });
  }

  try {
    const scopes = [
      'https://www.googleapis.com/auth/calendar.readonly',
      'https://www.googleapis.com/auth/calendar.events.readonly'
    ];

    const params = new URLSearchParams({
      client_id: GOOGLE_CLIENT_ID,
      redirect_uri: REDIRECT_URI,
      response_type: 'code',
      scope: scopes.join(' '),
      access_type: 'offline',
      prompt: 'consent',
      include_granted_scopes: 'true'
    });

    const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`;
    
    console.log('Generated auth URL:', authUrl.substring(0, 100) + '...');
    res.status(200).json({ authUrl });
  } catch (error: any) {
    console.error('Calendar auth error:', error);
    res.status(500).json({ error: 'Failed to generate auth URL', details: error.message });
  }
}
