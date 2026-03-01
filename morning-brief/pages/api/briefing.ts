import type { NextApiRequest, NextApiResponse } from 'next';
import axios from 'axios';

const BRAVE_API_KEY = process.env.BRAVE_API_KEY?.trim();
const FOOTBALL_DATA_API_KEY = process.env.FOOTBALL_DATA_API_KEY?.trim();
const OPENAI_API_KEY = process.env.OPENAI_API_KEY?.trim();

// Fetch Arsenal injuries/squad status
async function fetchArsenalInjuries(): Promise<Array<{ player: string; status: string; notes: string }>> {
  try {
    if (!BRAVE_API_KEY) {
      return [{ player: 'Saka', status: 'FIT', notes: 'Available' }, { player: 'Odegaard', status: 'FIT', notes: 'Available' }];
    }

    const res = await axios.get(
      `https://api.search.brave.com/res/v1/web/search?q=${encodeURIComponent('Arsenal injuries team news latest')}&count=5`,
      {
        headers: { 'X-Subscription-Token': BRAVE_API_KEY, 'Accept': 'application/json' },
        timeout: 8000
      }
    );

    const results = res.data?.web?.results || [];

    // Parse injury news from descriptions
    const injuries: Array<{ player: string; status: string; notes: string }> = [];

    for (const result of results.slice(0, 3)) {
      const text = (result.title + ' ' + result.description).toLowerCase();

      // Look for common injury patterns
      const injuryPatterns = [
        { player: 'Saka', pattern: /saka.*(?:injured|knock|doubt)/i },
        { player: 'Odegaard', pattern: /odegaard.*(?:injured|knock|doubt)/i },
        { player: 'Saliba', pattern: /saliba.*(?:injured|knock|doubt)/i },
        { player: 'Rice', pattern: /rice.*(?:injured|knock|doubt)/i },
        { player: 'Havertz', pattern: /havertz.*(?:injured|knock|doubt)/i },
        { player: 'Saka', fitPattern: /saka.*(?:fit|available|starts)/i },
        { player: 'Odegaard', fitPattern: /odegaard.*(?:fit|available|starts)/i },
        { player: 'Saliba', fitPattern: /saliba.*(?:fit|available|starts)/i },
      ];

      for (const { player, pattern, fitPattern } of injuryPatterns) {
        if (pattern && pattern.test(text)) {
          if (!injuries.find(i => i.player === player)) {
            injuries.push({ player, status: 'DOUBT', notes: 'Check latest' });
          }
        } else if (fitPattern && fitPattern.test(text)) {
          if (!injuries.find(i => i.player === player)) {
            injuries.push({ player, status: 'FIT', notes: 'Available' });
          }
        }
      }
    }

    // Default to key players if no specific injury news found
    if (injuries.length === 0) {
      return [
        { player: 'Saka', status: 'FIT', notes: 'Available' },
        { player: 'Odegaard', status: 'FIT', notes: 'Available' },
        { player: 'Saliba', status: 'FIT', notes: 'Available' }
      ];
    }

    return injuries;
  } catch (e) {
    return [{ player: 'Saka', status: 'FIT', notes: 'Available' }, { player: 'Odegaard', status: 'FIT', notes: 'Available' }];
  }
}

// Types
interface WeatherData {
  temp: number;
  condition: string;
  high: number;
  low: number;
  humidity: string;
  wind: string;
  precip: string;
  forecast: string[];
}

interface CryptoData {
  prices: {
    bitcoin: { price: string; change: string; up: boolean };
    ethereum: { price: string; change: string; up: boolean };
    solana: { price: string; change: string; up: boolean };
  };
  sentiment: string;
  metrics: Array<{ label: string; value: string; note: string }>;
}

interface ArsenalData {
  lastMatch: {
    score: string;
    opponent: string;
    headline: string;
    description?: string;
    url?: string;
  };
  upcoming: Array<{ opponent: string; date: string; competition: string }>;
  injuries: Array<{ player: string; status: string; notes: string }>;
  trendingNews: Array<{ title: string; source: string; url: string }>;
  table: Array<{ position: number; team: string; played: number; won: number; points: number; form: string }>;
}

interface RedditPost {
  title: string;
  score: number;
  comments: number;
  url: string;
}

interface RedditData {
  subreddit: string;
  posts: RedditPost[];
}

// Helper functions
async function fetchWeather(): Promise<WeatherData> {
  try {
    const res = await axios.get('https://wttr.in/Princeton,NJ?format=j1', { timeout: 5000 });
    const current = res.data.current_condition[0];
    const forecast = res.data.weather.slice(0, 3);
    return {
      temp: Math.round(parseInt(current.temp_F)),
      condition: current.weatherDesc[0].value,
      high: Math.round(parseInt(forecast[0].maxtempF)),
      low: Math.round(parseInt(forecast[0].mintempF)),
      humidity: current.humidity,
      wind: current.windspeedMiles,
      precip: forecast[0].hourly[0].chanceofrain + '%',
      forecast: forecast.map((d: any) => `${new Date(d.date).toLocaleDateString('en-US', { weekday: 'short' })}: ${d.weatherDesc[0].value}, ${d.maxtempF}°/${d.mintempF}°`)
    };
  } catch (e) {
    return { temp: 35, condition: 'Mist', high: 43, low: 34, humidity: '96', wind: '6', precip: '70%', forecast: ['Sat: Rain 43°/34°', 'Sun: Snow 36°/28°', 'Mon: Clear 41°/32°'] };
  }
}

async function fetchCryptoPrices(): Promise<CryptoData> {
  try {
    const res = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana&vs_currencies=usd&include_24hr_change=true', { timeout: 5000 });
    const fmt = (n: number, chg: number) => ({ price: '$' + n.toLocaleString(), change: (chg > 0 ? '+' : '') + chg.toFixed(2) + '%', up: chg > 0 });
    return {
      prices: {
        bitcoin: fmt(res.data.bitcoin.usd, res.data.bitcoin.usd_24h_change),
        ethereum: fmt(res.data.ethereum.usd, res.data.ethereum.usd_24h_change),
        solana: fmt(res.data.solana.usd, res.data.solana.usd_24h_change)
      },
      sentiment: res.data.bitcoin.usd_24h_change > 0 ? 'Fear easing' : 'Extreme Fear',
      metrics: [{ label: 'BTC Dominance', value: '58%', note: 'Defensive' }, { label: 'Fear', value: res.data.bitcoin.usd_24h_change > 0 ? '28/100' : '18/100', note: 'Contrarian' }]
    };
  } catch (e) {
    return { prices: { bitcoin: { price: '$67,728', change: '+2.15%', up: true }, ethereum: { price: '$1,965', change: '+2.31%', up: true }, solana: { price: '$83.57', change: '+3.87%', up: true } }, sentiment: 'Extreme Fear', metrics: [{ label: 'BTC Dominance', value: '58%', note: 'Defensive' }, { label: 'Fear', value: '18/100', note: 'Contrarian' }] };
  }
}

async function fetchRedditPosts(): Promise<RedditData[]> {
  const subreddits = ['memes', 'soccer', 'Gunners', 'frugalmalefashion', 'malefashionadvice', 'wallstreetbets', 'technology', 'india'];
  try {
    const posts = await Promise.all(subreddits.map(async (sub) => {
      try {
        const res = await axios.get(`https://www.reddit.com/r/${sub}/hot.json?limit=2`, { headers: { 'User-Agent': 'MorningBrief/1.0' }, timeout: 5000 });
        return { subreddit: sub, posts: res.data?.data?.children?.slice(0, 2).map((post: any) => ({ title: post.data.title?.slice(0, 80), score: post.data.score, comments: post.data.num_comments, url: `https://reddit.com${post.data.permalink}` })) || [] };
      } catch (e) { return { subreddit: sub, posts: [] }; }
    }));
    return posts.filter(p => p.posts.length > 0);
  } catch (e) { return [{ subreddit: 'wallstreetbets', posts: [{ title: 'Markets in chaos', score: 15000, comments: 800, url: 'https://reddit.com/r/wallstreetbets' }] }]; }
}

async function fetchBlueskyFeed() {
  const handle = 'nikhilist.bsky.social';
  return { handle, followsCount: 351, timeline: [], summary: `Connected as @${handle}. You follow 351 accounts.`, profileUrl: `https://bsky.app/profile/${handle}`, feedUrl: `https://bsky.app/profile/${handle}/follows` };
}

async function fetchArsenalData(): Promise<ArsenalData> {
  try {
    if (!BRAVE_API_KEY) {
      throw new Error('No API key');
    }
    
    const [newsRes, fixturesRes] = await Promise.all([
      axios.get(`https://api.search.brave.com/res/v1/news/search?q=${encodeURIComponent('Arsenal FC latest result match')}&count=5`, {
        headers: { 'X-Subscription-Token': BRAVE_API_KEY, 'Accept': 'application/json' }, timeout: 8000
      }).catch(() => null),
      axios.get(`https://api.search.brave.com/res/v1/web/search?q=${encodeURIComponent('Arsenal FC fixtures 2026')}&count=3`, {
        headers: { 'X-Subscription-Token': BRAVE_API_KEY, 'Accept': 'application/json' }, timeout: 8000
      }).catch(() => null)
    ]);
    
    const news = newsRes?.data?.results || [];
    const fixtures = fixturesRes?.data?.web?.results || [];
    
    const resultNews = news.find((n: any) => {
      const title = n.title?.toLowerCase() || '';
      return title.includes('arsenal') && 
        (title.includes('beat') || title.includes('win') || title.includes('victory') ||
         title.includes('defeat') || title.includes('draw') || title.match(/\d+\s*[-–—]\s*\d+/));
    });
    
    let lastScore = '-';
    let opponent = 'Opponent';
    if (resultNews) {
      const title = resultNews.title || '';
      const description = resultNews.description || '';
      const combinedText = title + ' ' + description;

      // Look for match scores in both title and description (1-2 digits on each side, avoid years like 2025-26)
      const scoreMatch = combinedText.match(/(\d{1,2})\s*[-–—:]\s*(\d{1,2})/);
      if (scoreMatch) {
        const first = parseInt(scoreMatch[1]);
        const second = parseInt(scoreMatch[2]);
        // Validate it's actually a match score (not a year)
        if (first <= 20 && second <= 20) {
          lastScore = `${scoreMatch[1]}-${scoreMatch[2]}`;
        }
      }
      if (lastScore === '-' && (combinedText.toLowerCase().includes('victory') || combinedText.toLowerCase().includes('win'))) {
        lastScore = 'WIN';
      } else if (lastScore === '-' && combinedText.toLowerCase().includes('defeat')) {
        lastScore = 'LOSS';
      } else if (lastScore === '-' && combinedText.toLowerCase().includes('draw')) {
        lastScore = 'DRAW';
      }

      // Extract opponent from title (prioritize "vs TEAM" or "beat TEAM")
      const vsMatch = title.match(/(?:Arsenal\s+)?(?:vs\.?|beat)\s+([A-Z][a-zA-Z\s]+?)(?:\s+\d|$|\s+to\s+|\s+in\s+|\s+-|\s+at\s+)/i);
      if (vsMatch) opponent = vsMatch[1].trim();
      else {
        // Fallback: look for "Chelsea" or other team names in title
        const teamMatch = title.match(/Arsenal\s+(?:vs\.?|beat)\s+([A-Z][a-zA-Z]+)/i);
        if (teamMatch) opponent = teamMatch[1].trim();
      }
    }
    
    // Fetch proper upcoming fixtures - search for specific match previews
    let upcomingMatches: any[] = [];
    try {
      const fixturesRes = await axios.get(
        `https://api.search.brave.com/res/v1/web/search?q=${encodeURIComponent('Arsenal next match preview vs opponent 2026')}&count=5`,
        {
          headers: { 'X-Subscription-Token': BRAVE_API_KEY, 'Accept': 'application/json' },
          timeout: 8000
        }
      );

      const fixtures = fixturesRes.data?.web?.results || [];

      // Filter out schedule/season pages and find actual match previews
      const validFixtures = fixtures.filter((f: any) => {
        const title = f.title || '';
        const desc = f.description || '';
        // Skip season overview pages
        if (/202\d-2\d/.test(title)) return false;
        if (/schedule.*202\d/i.test(title)) return false;
        if (/season\s*202\d/i.test(title)) return false;
        if (/premier league table/i.test(title)) return false;
        // Look for actual match previews with vs
        return (title.toLowerCase().includes('vs') || title.toLowerCase().includes('v ')) &&
               (title.toLowerCase().includes('preview') || title.toLowerCase().includes('next') ||
                desc.toLowerCase().includes('kick off') || desc.toLowerCase().includes('fixture'));
      });

      upcomingMatches = validFixtures.slice(0, 3).map((f: any) => {
        const title = f.title || '';
        let opponent = 'TBC';

        // Extract opponent from "Arsenal vs TEAM" or "TEAM vs Arsenal"
        const vsMatch = title.match(/Arsenal\s+(?:vs\.?|v)\s+([A-Z][a-zA-Z\s]+?)(?:\s+\||\s+-|\s+preview|\s+at\s+|\s+202\d|$)/i);
        const vsBefore = title.match(/([A-Z][a-zA-Z\s]+?)\s+(?:vs\.?|v)\s+Arsenal/i);

        if (vsMatch) opponent = vsMatch[1].trim();
        else if (vsBefore) opponent = vsBefore[1].trim();

        // Extract date from description if available
        let date = 'TBD';
        const desc = f.description || '';
        const dayMatch = desc.match(/(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday),?\s+(\w+\s+\d{1,2})/i);
        const shortDayMatch = desc.match(/(Mon|Tue|Wed|Thu|Fri|Sat|Sun)[a-z]*\s+(\w+\s+\d{1,2})/i);

        if (dayMatch) date = `${dayMatch[1]} ${dayMatch[2]}`;
        else if (shortDayMatch) date = `${shortDayMatch[1]} ${shortDayMatch[2]}`;

        // Competition detection
        let competition = 'TBC';
        const checkText = (title + ' ' + desc).toLowerCase();
        if (checkText.includes('premier league')) competition = 'Premier League';
        else if (checkText.includes('champions league')) competition = 'Champions League';
        else if (checkText.includes('fa cup')) competition = 'FA Cup';
        else if (checkText.includes('carabao') || checkText.includes('league cup')) competition = 'League Cup';
        else if (checkText.includes('europa')) competition = 'Europa League';

        return { opponent, date, competition };
      });
    } catch (e) {
      console.log('Fixture fetch failed:', e);
    }
    
    // Get trending news from main search
    const trendingNews = news.slice(0, 3).map((n: any) => ({
      title: n.title,
      source: n.source,
      url: n.url
    }));

    // Try to get arseblog news specifically
    let arseblogNews: any[] = [];
    try {
      const arseblogRes = await axios.get(
        `https://api.search.brave.com/res/v1/news/search?q=${encodeURIComponent('site:arseblog.news Arsenal')}&count=5`,
        {
          headers: { 'X-Subscription-Token': BRAVE_API_KEY, 'Accept': 'application/json' },
          timeout: 8000
        }
      );
      const arseblogResults = arseblogRes.data?.results || [];
      arseblogNews = arseblogResults.slice(0, 3).map((n: any) => ({
        title: n.title,
        source: 'Arseblog',
        url: n.url
      }));
    } catch (e) {
      console.log('Arseblog fetch failed:', e);
    }

    // Combine news, prioritizing arseblog
    const combinedNews = arseblogNews.length > 0 ? arseblogNews : trendingNews;
    
    let tableData = [];
    try {
      const headers: any = {};
      if (FOOTBALL_DATA_API_KEY) {
        headers['X-Auth-Token'] = FOOTBALL_DATA_API_KEY;
      }
      
      const tableRes = await axios.get('https://api.football-data.org/v4/competitions/PL/standings', {
        headers,
        timeout: 8000
      });
      
      const standings = tableRes.data?.standings?.[0]?.table || [];
      tableData = standings.slice(0, 5).map((team: any) => ({
        position: team.position,
        team: team.team.shortName || team.team.name,
        played: team.playedGames,
        won: team.won,
        points: team.points,
        form: team.form || '---'
      }));
    } catch (e: any) {
      console.log('Football-data API error:', e?.message);
      tableData = [
        { position: 1, team: 'Liverpool', played: 24, won: 18, points: 60, form: 'WWWDW' },
        { position: 2, team: 'Arsenal', played: 24, won: 14, points: 47, form: 'WWDLW' },
        { position: 3, team: 'Nottm Forest', played: 24, won: 14, points: 47, form: 'WDWLW' }
      ];
    }
    
    return {
      lastMatch: {
        score: lastScore,
        opponent: opponent,
        headline: resultNews?.title || 'Latest match',
        description: resultNews?.description?.slice(0, 100),
        url: resultNews?.url
      },
      upcoming: upcomingMatches.length > 0 ? upcomingMatches : [
        { opponent: 'Check fixtures', date: 'TBD', competition: 'Premier League' },
        { opponent: 'TBC', date: 'TBD', competition: 'TBC' },
        { opponent: 'TBC', date: 'TBD', competition: 'TBC' }
      ],
      injuries: await fetchArsenalInjuries(),
      trendingNews: combinedNews.length > 0 ? combinedNews : [{ title: 'Arsenal news loading...', source: 'System', url: '#' }],
      table: tableData
    };
    
  } catch (e: any) {
    console.log('Arsenal fetch error:', e?.message);
    return {
      lastMatch: { score: '-', opponent: 'TBC', headline: 'Fetching latest...', description: 'Refresh to update' },
      upcoming: [{ opponent: 'Check Brave API', date: 'TBD', competition: 'PL' }, { opponent: 'TBC', date: 'TBD', competition: 'TBC' }, { opponent: 'TBC', date: 'TBD', competition: 'TBC' }],
      injuries: [{ player: 'Saka', status: 'FIT', notes: 'Available' }, { player: 'Odegaard', status: 'FIT', notes: 'Available' }],
      trendingNews: [{ title: 'Connect Brave API for live data', source: 'System', url: '#' }],
      table: [
        { position: 1, team: 'Liverpool', played: 24, won: 18, points: 60, form: 'WWWDW' },
        { position: 2, team: 'Arsenal', played: 24, won: 14, points: 47, form: 'WWDLW' },
        { position: 3, team: 'Nottm Forest', played: 24, won: 14, points: 47, form: 'WDWLW' }
      ]
    };
  }
}

async function fetchViralTrends() {
  return [
    { topic: 'Memes', category: 'MEMES', icon: '🤣', content: [{ headline: 'Viral content loading...', detail: 'Refresh for latest', platform: 'Reddit', url: '#' }] }
  ];
}

function generateTradfiUpdate() {
  return {
    marketContext: { fedPolicy: 'Rates peaked. Cuts mid-2026.', tariffImpact: 'SCOTUS clears overhang.', aiCycle: 'AI buildout—2-3 years.', rotationWatch: 'Mid-caps attracting flows.' },
    macroThemes: [{ theme: 'AI Infrastructure', impact: 'Massive', description: 'NVDA, ALAB, VRT.' }, { theme: 'Cybersecurity', impact: 'High', description: 'CRWD, NBIS.' }]
  };
}

// Template-based fallback insights generator
function generateTemplateInsights({ dayName, isWeekend, weather, crypto, redditData, arsenalData }: any) {
  const btcUp = crypto?.prices?.bitcoin?.up ?? false;
  const arsenalWon = arsenalData?.lastMatch?.score?.includes('WIN') || 
    (arsenalData?.lastMatch?.score?.match && arsenalData?.lastMatch?.score?.match(/^\d+-\d+$/) && 
     parseInt(arsenalData?.lastMatch?.score?.split('-')[0]) > parseInt(arsenalData?.lastMatch?.score?.split('-')[1]));
  
  return {
    weather: {
      immediate: `It's ${weather?.temp || 35}°F with ${weather?.condition?.toLowerCase() || 'clear'}.`,
      todayStrategy: `${weather?.precip || '0%'} chance of rain.`,
      tomorrowAnchor: `Tomorrow: ${weather?.forecast?.[1] || 'Clear'}.`
    },
    crypto: {
      macroContext: btcUp ? 'Bitcoin up—fear easing.' : 'Bitcoin down—accumulation time.',
      smartMoneySignals: btcUp ? 'Relief rally?' : 'Whales accumulating.',
      contrarianSetup: 'Extreme fear = opportunity.'
    },
    strategy: {
      dailyFocus: `${dayName}: ${isWeekend ? 'Rest & prep' : 'Deep work'}.`,
      strategicAssessment: `Markets ${btcUp ? 'recovering' : 'washing out'}. Stay rational.`,
      blindspots: ['Weather check', 'Crypto FOMO', 'Work-life balance'],
      opportunities: ['Family time', 'DCA if accumulating', 'Reading block'],
      tacticalMoves: ['Set price alerts', 'Block focus time', 'Prep for week'],
      patternAnalysis: 'Your weekend pattern: Friday decompression → Saturday catch-up → Sunday drift → Monday scramble.'
    }
  };
}

// LLM-powered insights generator
async function generateLLMInsights({ 
  dayName, 
  isWeekend, 
  weather, 
  crypto, 
  redditData, 
  arsenalData,
  today,
  stocks
}: { 
  dayName: string;
  isWeekend: boolean;
  weather: WeatherData;
  crypto: CryptoData;
  redditData: RedditData[];
  arsenalData: ArsenalData;
  today: Date;
  stocks?: any;
}): Promise<any> {
  // If no OpenAI key, use templates
  if (!OPENAI_API_KEY) {
    return generateTemplateInsights({ dayName, isWeekend, weather, crypto, redditData, arsenalData });
  }

  try {
    const { default: OpenAI } = await import('openai');
    const openai = new OpenAI({ apiKey: OPENAI_API_KEY });

    const arsenalResult = arsenalData?.lastMatch?.score !== '-' 
      ? `${arsenalData.lastMatch.score} vs ${arsenalData.lastMatch.opponent}`
      : 'No recent result';
    const arsenalPosition = arsenalData?.table?.find((t: any) => t.team?.includes('Arsenal'))?.position || 'unknown';
    
    const prompt = `Generate a personalized morning brief for Nik. Context:
- Location: Princeton, NJ
- Weather: ${weather.temp}°F, ${weather.condition}, ${weather.precip} chance of rain
- Day: ${dayName} (${isWeekend ? 'weekend' : 'workday'})
- Crypto: BTC ${crypto.prices.bitcoin.change}, sentiment: ${crypto.sentiment}
- Arsenal: Last match ${arsenalResult}, table position: ${arsenalPosition}
- Reddit trending: ${redditData.slice(0, 2).map(r => r.subreddit).join(', ')}
- Stocks: ${stocks?.summary ? `${stocks.summary.gainers} up, ${stocks.summary.losers} down` : 'N/A'}

Nik is an Engineering Lead working from home, spouse Meg works in NYC, son Neel is 3 years old. Family is top priority.

Respond with ONLY a JSON object in this exact format:
{
  "weather": {
    "immediate": "1 sentence about current weather",
    "todayStrategy": "1 sentence advice for the day",
    "tomorrowAnchor": "1 sentence about tomorrow"
  },
  "crypto": {
    "macroContext": "1 sentence market context",
    "smartMoneySignals": "1 sentence about what smart money is doing", 
    "contrarianSetup": "1 sentence contrarian opportunity"
  },
  "strategy": {
    "strategicAssessment": "2-3 sentence daily overview",
    "blindspots": ["blindspot 1", "blindspot 2", "blindspot 3"],
    "opportunities": ["opportunity 1", "opportunity 2", "opportunity 3"],
    "patternAnalysis": "1 sentence about patterns"
  }
}`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'You are a sharp, insightful assistant. Be concise, practical, and slightly witty. Avoid corporate speak.' },
        { role: 'user', content: prompt }
      ],
      temperature: 0.7,
      max_tokens: 800
    });

    const content = completion.choices[0]?.message?.content || '';
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
    throw new Error('No JSON in response');
  } catch (e) {
    console.log('LLM failed, using templates:', e);
    return generateTemplateInsights({ dayName, isWeekend, weather, crypto, redditData, arsenalData });
  }
}

// Fetch calendar events - requires access token from client
async function fetchCalendarEvents(accessToken?: string) {
  if (!accessToken) {
    return {
      today: { date: new Date().toISOString(), dayName: 'Today', events: [] },
      tomorrow: { date: new Date(Date.now() + 86400000).toISOString(), dayName: 'Tomorrow', events: [] },
      connected: false,
      error: 'Calendar not connected'
    };
  }

  try {
    // We can't call our own API easily from serverless, so return minimal data
    // The client will fetch full calendar data directly
    return {
      today: { date: new Date().toISOString(), dayName: 'Today', events: [] },
      tomorrow: { date: new Date(Date.now() + 86400000).toISOString(), dayName: 'Tomorrow', events: [] },
      connected: true,
      accessToken
    };
  } catch (e) {
    return {
      today: { date: new Date().toISOString(), dayName: 'Today', events: [] },
      tomorrow: { date: new Date(Date.now() + 86400000).toISOString(), dayName: 'Tomorrow', events: [] },
      connected: false,
      error: 'Failed to fetch calendar'
    };
  }
}

// Fetch stocks data
async function fetchStocksData() {
  try {
    const res = await axios.get('http://localhost:3000/api/stocks', { timeout: 10000 });
    return res.data;
  } catch (e) {
    // Fallback: fetch from same origin
    return null;
  }
}

// Main handler
export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  try {
    const today = new Date();
    const dayName = today.toLocaleDateString('en-US', { weekday: 'long' });
    const isWeekend = today.getDay() === 0 || today.getDay() === 6;
    
    const [weatherData, cryptoData, redditData, blueskyData, arsenalData, calendarData] = await Promise.all([
      fetchWeather(), fetchCryptoPrices(), fetchRedditPosts(), fetchBlueskyFeed(), fetchArsenalData(), fetchCalendarEvents()
    ]);

    // Fetch stocks separately (might be slow)
    const stocksData = await fetchStocksData().catch(() => null);

    // Generate insights using LLM if available, otherwise templates
    const insights = await generateLLMInsights({ 
      dayName, 
      isWeekend, 
      weather: weatherData, 
      crypto: cryptoData, 
      redditData, 
      arsenalData,
      today,
      stocks: stocksData
    });

    const viralData = await fetchViralTrends();
    
    res.status(200).json({
      weather: { ...weatherData, insights: insights.weather },
      arsenal: arsenalData,
      crypto: { ...cryptoData, insights: insights.crypto },
      tradfi: generateTradfiUpdate(),
      reddit: redditData,
      bluesky: blueskyData,
      viral: viralData,
      calendar: calendarData,
      stocks: stocksData,
      strategy: insights.strategy,
      meta: { 
        generatedAt: today.toISOString(), 
        version: '3.2.0',
        insightsSource: OPENAI_API_KEY ? 'llm' : 'template'
      }
    });
  } catch (error) {
    console.error('Briefing generation error:', error);
    res.status(500).json({ error: 'Failed to generate briefing' });
  }
}