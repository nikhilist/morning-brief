import type { NextApiRequest, NextApiResponse } from 'next';
import { google } from 'googleapis';

const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;
const REDIRECT_URI = process.env.GOOGLE_REDIRECT_URI || 'http://localhost:3000/api/calendar/callback';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { code } = req.query;

  if (!code || typeof code !== 'string') {
    return res.status(400).json({ error: 'No code provided' });
  }

  if (!GOOGLE_CLIENT_ID || !GOOGLE_CLIENT_SECRET) {
    return res.status(500).json({ error: 'Calendar not configured' });
  }

  try {
    const oauth2Client = new google.auth.OAuth2(
      GOOGLE_CLIENT_ID,
      GOOGLE_CLIENT_SECRET,
      REDIRECT_URI
    );

    const { tokens } = await oauth2Client.getToken(code);

    // In production, store these tokens securely (encrypted in DB or secure cookie)
    // For now, redirect back to home with tokens in query (not secure for production)
    const accessToken = tokens.access_token;
    const refreshToken = tokens.refresh_token;

    // Redirect back to home page
    const redirectUrl = `/?calendar_connected=1&access_token=${accessToken}${refreshToken ? `&refresh_token=${refreshToken}` : ''}`;
    res.redirect(redirectUrl);
  } catch (error) {
    console.error('Calendar callback error:', error);
    res.status(500).json({ error: 'Failed to authenticate' });
  }
}
