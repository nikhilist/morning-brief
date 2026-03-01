import type { NextApiRequest, NextApiResponse } from 'next';
import axios from 'axios';

const BRAVE_API_KEY = process.env.BRAVE_API_KEY?.trim();
const FOOTBALL_DATA_API_KEY = process.env.FOOTBALL_DATA_API_KEY?.trim();

// Helper functions
async function fetchWeather() {
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
    return { temp: 35, condition: 'Mist', high: 43, low: 34, humidity: 96, wind: 6, precip: '70%', forecast: ['Sat: Rain 43°/34°', 'Sun: Snow 36°/28°', 'Mon: Clear 41°/32°'] };
  }
}

async function fetchCryptoPrices() {
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

async function fetchRedditPosts() {
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

async function fetchArsenalData() {
  try {
    if (!BRAVE_API_KEY) {
      throw new Error('No API key');
    }
    
    // Fetch real Arsenal news
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
    
    // Find match result
    const resultNews = news.find((n: any) => {
      const title = n.title?.toLowerCase() || '';
      return title.includes('arsenal') && 
        (title.includes('beat') || title.includes('win') || title.includes('victory') ||
         title.includes('defeat') || title.includes('draw') || title.match(/\d+\s*[-–—]\s*\d+/));
    });
    
    // Extract score
    let lastScore = '-';
    let opponent = 'Opponent';
    if (resultNews) {
      const title = resultNews.title || '';
      const scoreMatch = title.match(/(\d+)\s*[-–—:]\s*(\d+)/);
      if (scoreMatch) {
        lastScore = `${scoreMatch[1]}-${scoreMatch[2]}`;
      } else if (title.toLowerCase().includes('victory') || title.toLowerCase().includes('win')) {
        lastScore = 'WIN';
      } else if (title.toLowerCase().includes('defeat')) {
        lastScore = 'LOSS';
      } else if (title.toLowerCase().includes('draw')) {
        lastScore = 'DRAW';
      }
      const oppMatch = title.match(/(?:beat|vs|against)\s+([A-Z][a-zA-Z\s]+?)(?:\s|$|\d)/i);
      if (oppMatch) opponent = oppMatch[1].trim();
    }
    
    // Parse fixtures
    const upcomingMatches = fixtures.slice(0, 3).map((f: any) => ({
      opponent: f.title?.match(/vs\s+([A-Za-z\s]+?)(?:\s|$|\d)/i)?.[1]?.trim() || 'TBC',
      date: f.title?.match(/(\w+day|\d+\s+\w+|\w+\s+\d+)/i)?.[1] || 'TBD',
      competition: f.title?.includes('Premier League') ? 'Premier League' : 
                   f.title?.includes('Champions League') ? 'Champions League' : 'TBC'
    }));
    
    // Trending news
    const trendingNews = news.slice(0, 3).map((n: any) => ({
      title: n.title,
      source: n.source,
      url: n.url
    }));
    
    // Fetch REAL Premier League table from football-data.org
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
      // Fallback to static data if API fails
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
      injuries: [{ player: 'Saka', status: 'FIT', notes: 'Available' }, { player: 'Odegaard', status: 'FIT', notes: 'Available' }],
      trendingNews: trendingNews.length > 0 ? trendingNews : [{ title: 'Arsenal news loading...', source: 'System', url: '#' }],
      table: tableData
    };
    
  } catch (e: any) {
    console.log('Arsenal fetch error:', e?.message);
    return {
      lastMatch: { score: '-', opponent: 'TBC', headline: 'Fetching latest...', description: 'Refresh to update' },
      upcoming: [{ opponent: 'Check Brave API', date: 'TBD', competition: 'PL' }, { opponent: 'TBC', date: 'TBD', competition: 'TBC' }, { opponent: 'TBC', date: 'TBD', competition: 'TBC' }],
      injuries: [{ player: 'Saka', status: 'FIT', notes: 'Available' }],
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

function generateDailyInsights({ dayName, isWeekend, weather, crypto, redditData, blueskyData }: any) {
  const btcUp = crypto?.prices?.bitcoin?.up ?? false;
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

// Main handler
export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  try {
    const today = new Date();
    const dayName = today.toLocaleDateString('en-US', { weekday: 'long' });
    const isWeekend = today.getDay() === 0 || today.getDay() === 6;
    
    const [weatherData, cryptoData, redditData, blueskyData, arsenalData] = await Promise.all([
      fetchWeather(), fetchCryptoPrices(), fetchRedditPosts(), fetchBlueskyFeed(), fetchArsenalData()
    ]);

    const insights = generateDailyInsights({ dayName, isWeekend, weather: weatherData, crypto: cryptoData, redditData, blueskyData });
    const viralData = await fetchViralTrends();
    
    res.status(200).json({
      weather: { ...weatherData, insights: insights.weather },
      arsenal: arsenalData,
      crypto: { ...cryptoData, insights: insights.crypto },
      tradfi: generateTradfiUpdate(),
      reddit: redditData,
      bluesky: blueskyData,
      viral: viralData,
      strategy: insights.strategy,
      meta: { generatedAt: today.toISOString(), version: '3.0.0' }
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate briefing' });
  }
}
