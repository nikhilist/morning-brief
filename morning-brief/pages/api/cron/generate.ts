import type { NextApiRequest, NextApiResponse } from 'next';
import axios from 'axios';

// Cron job handler - triggers at 5 AM daily
export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  // Verify cron secret if configured
  const cronSecret = req.headers['x-vercel-cron-secret'] || req.query.secret;
  
  // Only allow cron or authorized requests
  if (process.env.CRON_SECRET && cronSecret !== process.env.CRON_SECRET) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    // Generate the briefing
    const briefingRes = await axios.get(
      `${process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : 'http://localhost:3000'}/api/briefing`,
      { timeout: 30000 }
    );

    // Optionally send to Telegram
    if (process.env.TELEGRAM_BOT_TOKEN && process.env.TELEGRAM_CHAT_ID) {
      const summary = generateTelegramSummary(briefingRes.data);
      
      await axios.post(
        `https://api.telegram.org/bot${process.env.TELEGRAM_BOT_TOKEN}/sendMessage`,
        {
          chat_id: process.env.TELEGRAM_CHAT_ID,
          text: summary,
          parse_mode: 'HTML',
          disable_web_page_preview: true
        }
      );
    }

    res.status(200).json({ 
      success: true, 
      generatedAt: new Date().toISOString(),
      message: 'Morning briefing generated successfully'
    });
  } catch (error) {
    console.error('Cron job error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to generate briefing' 
    });
  }
}

function generateTelegramSummary(data: any): string {
  const { weather, arsenal, crypto, hackernews, strategy } = data;
  
  return `
🌅 <b>Good Morning!</b>

🌤️ <b>Princeton:</b> ${weather.temp}°F, ${weather.condition}
📊 High: ${weather.high}°F • Low: ${weather.low}°F

⚽ <b>Arsenal vs Spurs</b> — Tomorrow 11:30 AM ET
${arsenal.injuries.filter((i: any) => i.status !== 'FIT').map((i: any) => `• ${i.player}: ${i.status}`).join('\n')}

💰 <b>Crypto</b>
BTC: ${crypto.bitcoin.price} (${crypto.bitcoin.change})
ETH: ${crypto.ethereum.price} (${crypto.ethereum.change})
Sentiment: ${crypto.sentiment}

🧠 <b>Today's Focus</b>
${strategy.dailyFocus}

🔗 <a href="https://nik-sites.vercel.app/dashboard">Full Dashboard</a>
`;
}
