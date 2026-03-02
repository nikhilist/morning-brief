import type { NextApiRequest, NextApiResponse } from 'next';

const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;
const REDIRECT_URI = process.env.GOOGLE_REDIRECT_URI || 'https://morning-brief-nine.vercel.app/api/calendar/callback';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { code } = req.query;

  if (!code || typeof code !== 'string') {
    return res.status(400).json({ error: 'No code provided' });
  }

  if (!GOOGLE_CLIENT_ID || !GOOGLE_CLIENT_SECRET) {
    return res.status(500).json({ error: 'Calendar not configured' });
  }

  try {
    // Exchange code for tokens
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code,
        client_id: GOOGLE_CLIENT_ID,
        client_secret: GOOGLE_CLIENT_SECRET,
        redirect_uri: REDIRECT_URI,
        grant_type: 'authorization_code',
      }),
    });

    const tokens = await tokenResponse.json();

    if (!tokenResponse.ok || !tokens.access_token) {
      console.error('Token exchange failed:', tokens);
      return res.status(500).json({ error: 'Failed to exchange code for tokens', details: tokens });
    }

    // Store tokens in HttpOnly cookies (never expose in URL)
    const accessToken = tokens.access_token;
    const refreshToken = tokens.refresh_token || '';
    const cookieOptions = 'HttpOnly; Secure; SameSite=Strict; Path=/';

    const cookies = [
      `calendar_access_token=${encodeURIComponent(accessToken)}; ${cookieOptions}; Max-Age=3600`,
    ];
    if (refreshToken) {
      cookies.push(`calendar_refresh_token=${encodeURIComponent(refreshToken)}; ${cookieOptions}`);
    }
    res.setHeader('Set-Cookie', cookies);

    // Redirect cleanly — no tokens in the URL
    res.redirect('/?calendar_connected=1');
  } catch (error: any) {
    console.error('Calendar callback error:', error);
    res.status(500).json({ error: 'Failed to authenticate', details: error.message });
  }
}
