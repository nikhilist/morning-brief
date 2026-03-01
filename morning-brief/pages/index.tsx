'use client';

import { useState, useEffect } from 'react';
import { Cloud, Trophy, TrendingUp, DollarSign, Flame, Brain, RefreshCw, Moon, Sun, Wind, Droplets, Globe, MapPin, BarChart3, TrendingDown, Activity, Calendar as CalendarIcon, Clock, Video, MapPin as LocationIcon, ExternalLink, Link2 } from 'lucide-react';

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

interface CalendarData {
  today: CalendarDay;
  tomorrow: CalendarDay;
  connected: boolean;
  error?: string;
}

interface BriefingData {
  weather: any;
  arsenal: any;
  crypto: any;
  tradfi: any;
  reddit: any[];
  bluesky: any;
  viral: any[];
  strategy: any;
  stocks: any;
  calendar: CalendarData;
  meta: any;
}

export default function Dashboard() {
  const [data, setData] = useState<BriefingData | null>(null);
  const [loading, setLoading] = useState(true);
  const [darkMode, setDarkMode] = useState(true);
  const [calendarToken, setCalendarToken] = useState<string | null>(null);

  // Handle OAuth callback on mount
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const accessToken = urlParams.get('access_token');
    const refreshToken = urlParams.get('refresh_token');
    const connected = urlParams.get('calendar_connected');

    if (connected && accessToken) {
      localStorage.setItem('calendar_access_token', accessToken);
      if (refreshToken) {
        localStorage.setItem('calendar_refresh_token', refreshToken);
      }
      setCalendarToken(accessToken);
      // Clean up URL
      window.history.replaceState({}, document.title, window.location.pathname);
    } else {
      // Check localStorage
      const stored = localStorage.getItem('calendar_access_token');
      if (stored) setCalendarToken(stored);
    }
  }, []);

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 300000);
    return () => clearInterval(interval);
  }, [calendarToken]);

  const fetchData = async () => {
    try {
      const res = await fetch('/api/briefing');
      const json = await res.json();
      
      // If we have calendar token, fetch calendar events
      if (calendarToken) {
        try {
          const calRes = await fetch(`/api/calendar/events?access_token=${calendarToken}`);
          const calData = await calRes.json();
          json.calendar = calData;
        } catch (e) {
          console.error('Calendar fetch failed:', e);
        }
      }
      
      setData(json);
      setLoading(false);
    } catch (err) {
      console.error('Failed to fetch briefing:', err);
    }
  };

  if (loading) {
    return (
      <div className={`min-h-screen flex items-center justify-center ${darkMode ? 'bg-slate-900' : 'bg-gray-50'}`}>
        <div className="text-center">
          <RefreshCw className="w-16 h-16 animate-spin mx-auto mb-6 text-red-500" />
          <p className={`text-xl ${darkMode ? 'text-gray-300' : 'text-gray-600'}`}>Generating your morning briefing...</p>
        </div>
      </div>
    );
  }

  if (!data) return null;

  return (
    <div className={`min-h-screen transition-colors duration-300 ${darkMode ? 'bg-slate-900 text-white' : 'bg-gray-50 text-gray-900'}`}>
      {/* Header */}
      <header className={`sticky top-0 z-50 backdrop-blur-md border-b ${darkMode ? 'bg-slate-900/80 border-slate-800' : 'bg-white/80 border-gray-200'}`}>
        <div className="max-w-7xl mx-auto px-6 py-5">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold bg-gradient-to-r from-red-500 to-orange-500 bg-clip-text text-transparent">Morning Brief</h1>
              <p className={`text-base mt-1 ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>{new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}</p>
            </div>
            <div className="flex items-center gap-4">
              <button onClick={() => setDarkMode(!darkMode)} className={`p-3 rounded-lg ${darkMode ? 'hover:bg-slate-800' : 'hover:bg-gray-200'}`}>
                {darkMode ? <Sun className="w-6 h-6" /> : <Moon className="w-6 h-6" />}
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Floating Refresh Button */}
      <button 
        onClick={() => { setLoading(true); fetchData(); }}
        className="fixed bottom-6 right-6 z-50 p-4 bg-red-500 hover:bg-red-600 text-white rounded-full shadow-lg hover:shadow-xl transition-all flex items-center gap-2"
      >
        <RefreshCw className={`w-6 h-6 ${loading ? 'animate-spin' : ''}`} />
        <span className="font-semibold">Refresh</span>
      </button>

      <main className="max-w-7xl mx-auto px-6 py-8 space-y-6">
        {/* WEATHER */}
        <Section title="☁️ Weather — Princeton, NJ" darkMode={darkMode}>
          <div className="grid lg:grid-cols-3 gap-6">
            <div className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
              <div className="flex justify-between mb-4">
                <span className="text-6xl font-bold">{data.weather.temp}°F</span>
                <div className="text-right text-lg"><p>High: {data.weather.high}°F</p><p>Low: {data.weather.low}°F</p></div>
              </div>
              <p className="text-xl mb-4">{data.weather.condition}</p>
              <div className={`grid grid-cols-3 gap-4 p-4 rounded-lg ${darkMode ? 'bg-slate-700/50' : 'bg-gray-100'}`}>
                <div className="text-center"><Droplets className="w-6 h-6 mx-auto mb-2" /><p className="text-sm">Humidity</p><p className="font-semibold text-lg">{data.weather.humidity}%</p></div>
                <div className="text-center"><Wind className="w-6 h-6 mx-auto mb-2" /><p className="text-sm">Wind</p><p className="font-semibold text-lg">{data.weather.wind} mph</p></div>
                <div className="text-center"><Cloud className="w-6 h-6 mx-auto mb-2" /><p className="text-sm">Precip</p><p className="font-semibold text-lg">{data.weather.precip}</p></div>
              </div>
            </div>
            <div className="lg:col-span-2 space-y-4">
              <InsightBox title="⚡ Immediate Read" color="blue" darkMode={darkMode}>{data.weather.insights.immediate}</InsightBox>
              <InsightBox title="📅 Today's Strategy" color="yellow" darkMode={darkMode}>{data.weather.insights.todayStrategy}</InsightBox>
              <InsightBox title="🔮 Tomorrow's Setup" color="green" darkMode={darkMode}>{data.weather.insights.tomorrowAnchor}</InsightBox>
            </div>
          </div>
        </Section>

        {/* CALENDAR */}
        <CalendarSection
          calendar={data.calendar}
          darkMode={darkMode}
          onDisconnect={() => {
            localStorage.removeItem('calendar_access_token');
            localStorage.removeItem('calendar_refresh_token');
            setCalendarToken(null);
            fetchData();
          }}
        />

        {/* ARSENAL */}
        <Section title="⚽ Arsenal FC" darkMode={darkMode}>
          <div className="space-y-6">
            {/* Last Result - Big Display */}
            <div className={`p-8 rounded-xl text-center ${darkMode ? 'bg-green-900/20 border-2 border-green-500' : 'bg-green-50 border-2 border-green-500'}`}>
              <p className="text-sm text-green-400 font-semibold mb-2">🎯 LAST RESULT</p>
              <p className="text-7xl font-bold text-green-400 my-4">{data.arsenal.lastMatch?.score || '-'}</p>
              <p className="text-xl font-bold mb-1">vs {data.arsenal.lastMatch?.opponent}</p>
              <p className="text-base text-gray-400">{data.arsenal.lastMatch?.headline?.slice(0, 100)}...</p>
            </div>

            {/* Grid Layout for rest */}
            <div className="grid lg:grid-cols-3 gap-6">
              {/* Upcoming Fixtures */}
              <div className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
                <h3 className="font-bold text-lg mb-4 flex items-center gap-2">
                  <span>📅</span> Next 3 Games
                </h3>
                <div className="space-y-3">
                  {data.arsenal.upcoming?.map((match: any, i: number) => (
                    <div key={i} className={`p-3 rounded-lg ${darkMode ? 'bg-slate-700/50' : 'bg-gray-100'}`}>
                      <p className="font-semibold">vs {match.opponent}</p>
                      <p className="text-sm text-gray-400">{match.date}</p>
                      <p className="text-xs text-gray-500">{match.competition}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Injury Table */}
              <div className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
                <h3 className="font-bold text-lg mb-4 flex items-center gap-2">
                  <span>🏥</span> Injury Room
                </h3>
                <div className="space-y-2">
                  {data.arsenal.injuries?.map((inj: any, i: number) => (
                    <div key={i} className={`flex items-center justify-between p-3 rounded-lg ${darkMode ? 'bg-slate-700/30' : 'bg-gray-50'}`}>
                      <div>
                        <p className="font-semibold">{inj.player}</p>
                        <p className="text-xs text-gray-400">{inj.notes}</p>
                      </div>
                      <span className={`px-2 py-1 rounded text-xs font-bold ${
                        inj.status === 'FIT' ? 'bg-green-500/20 text-green-400' :
                        inj.status === 'DOUBT' ? 'bg-yellow-500/20 text-yellow-400' :
                        'bg-red-500/20 text-red-400'
                      }`}>{inj.status}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Trending News */}
              <div className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
                <h3 className="font-bold text-lg mb-4 flex items-center gap-2">
                  <span>🔥</span> Trending
                </h3>
                <div className="space-y-2">
                  {data.arsenal.trendingNews?.slice(0, 3).map((news: any, i: number) => (
                    <a key={i} href={news.url} target="_blank" rel="noopener noreferrer" className="block p-3 rounded-lg hover:opacity-80 transition-opacity ${darkMode ? 'bg-slate-700/50' : 'bg-gray-100'}">
                      <p className="text-sm font-medium text-blue-400 hover:underline line-clamp-2">{news.title}</p>
                      <p className="text-xs text-gray-500 mt-1">{news.source}</p>
                    </a>
                  ))}
                </div>
              </div>
            </div>

            {/* Premier League Table */}
            <div className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
              <h3 className="font-bold text-lg mb-4">🏆 Premier League Table (Top 5)</h3>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className={`${darkMode ? 'text-gray-400' : 'text-gray-600'} text-sm`}>
                      <th className="text-left p-2">#</th>
                      <th className="text-left p-2">Team</th>
                      <th className="text-center p-2">P</th>
                      <th className="text-center p-2">W</th>
                      <th className="text-center p-2">Pts</th>
                      <th className="text-left p-2">Form</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.arsenal.table?.map((team: any, i: number) => (
                      <tr key={i} className={`${team.team === 'Arsenal' ? (darkMode ? 'bg-green-900/20' : 'bg-green-50') : ''} ${darkMode ? 'border-t border-slate-700' : 'border-t border-gray-200'}`}>
                        <td className="p-2 font-bold">{team.position}</td>
                        <td className="p-2 font-semibold">{team.team}</td>
                        <td className="p-2 text-center">{team.played}</td>
                        <td className="p-2 text-center">{team.won}</td>
                        <td className="p-2 text-center font-bold">{team.points}</td>
                        <td className="p-2 text-xs">{team.form}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </Section>

        {/* CRYPTO */}
        <Section title="🪙 Crypto Markets" darkMode={darkMode}>
          <div className="grid lg:grid-cols-3 gap-6">
            <div className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
              {Object.entries(data.crypto.prices).map(([name, coin]: [string, any]) => (
                <div key={name} className={`flex justify-between p-4 rounded-lg mb-3 ${darkMode ? 'bg-slate-700/50' : 'bg-gray-100'}`}>
                  <span className="font-semibold text-lg capitalize">{name}</span>
                  <div className="text-right">
                    <p className="font-bold text-xl">{coin.price}</p>
                    <p className={`text-base ${coin.up ? 'text-green-400' : 'text-red-400'}`}>{coin.change}</p>
                  </div>
                </div>
              ))}
              <div className={`mt-4 p-4 rounded-lg ${darkMode ? 'bg-slate-700/30' : 'bg-gray-100'}`}>
                <p className="text-base font-semibold">Market Sentiment: <span className="text-red-400">{data.crypto.sentiment}</span></p>
              </div>
            </div>
            <div className="lg:col-span-2 space-y-4">
              <InsightBox title="🧠 Macro Context" color="yellow" darkMode={darkMode}>{data.crypto.insights.macroContext}</InsightBox>
              <InsightBox title="🐋 Smart Money Signals" color="green" darkMode={darkMode}>{data.crypto.insights.smartMoneySignals}</InsightBox>
              <InsightBox title="🎯 Contrarian Setup" color="purple" darkMode={darkMode}>{data.crypto.insights.contrarianSetup}</InsightBox>
            </div>
          </div>
        </Section>

        {/* TRADFI */}
        <Section title="📈 Traditional Markets" darkMode={darkMode}>
          <div className="grid md:grid-cols-2 gap-6">
            <div className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
              <h3 className="font-semibold text-lg mb-4">🌍 Macro Context</h3>
              <div className="space-y-3">
                {Object.entries(data.tradfi.marketContext).map(([key, value]: [string, any]) => (
                  <div key={key} className={`p-3 rounded-lg ${darkMode ? 'bg-slate-700/50' : 'bg-gray-100'}`}>
                    <p className="text-sm font-semibold capitalize mb-1">{key.replace(/([A-Z])/g, ' $1')}</p>
                    <p className="text-base text-gray-500">{value}</p>
                  </div>
                ))}
              </div>
            </div>
            <div className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
              <h3 className="font-semibold text-lg mb-4">🎯 Key Themes</h3>
              <div className="space-y-3">
                {data.tradfi.macroThemes.map((theme: any, i: number) => (
                  <div key={i} className={`p-3 rounded-lg border-l-4 ${i === 0 ? 'border-purple-500' : 'border-blue-500'} ${darkMode ? 'bg-slate-700/30' : 'bg-gray-50'}`}>
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-bold text-base">{theme.theme}</span>
                      <span className={`text-xs px-2 py-1 rounded ${theme.impact === 'Massive' ? 'bg-red-500/20 text-red-400' : 'bg-yellow-500/20 text-yellow-400'}`}>{theme.impact}</span>
                    </div>
                    <p className="text-base text-gray-500">{theme.description}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </Section>

        {/* STOCK WATCHLIST */}
        <Section title="📊 Stock Watchlist" darkMode={darkMode}>
          <div className="space-y-6">
            {/* Summary Stats */}
            {data.stocks?.summary && (
              <div className="grid grid-cols-4 gap-4">
                <div className={`p-4 rounded-xl text-center ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
                  <p className={`text-3xl font-bold ${darkMode ? 'text-blue-400' : 'text-blue-600'}`}>{data.stocks.summary.totalStocks}</p>
                  <p className="text-sm text-gray-500 mt-1">Total</p>
                </div>
                <div className={`p-4 rounded-xl text-center ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
                  <p className="text-3xl font-bold text-green-500">{data.stocks.summary.gainers}</p>
                  <p className="text-sm text-gray-500 mt-1">Gainers</p>
                </div>
                <div className={`p-4 rounded-xl text-center ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
                  <p className="text-3xl font-bold text-red-500">{data.stocks.summary.losers}</p>
                  <p className="text-sm text-gray-500 mt-1">Losers</p>
                </div>
                <div className={`p-4 rounded-xl text-center ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
                  <p className={`text-3xl font-bold ${data.stocks.summary.avgChange >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                    {data.stocks.summary.avgChange >= 0 ? '+' : ''}{data.stocks.summary.avgChange.toFixed(2)}%
                  </p>
                  <p className="text-sm text-gray-500 mt-1">Avg Change</p>
                </div>
              </div>
            )}

            {/* Stock Categories */}
            <div className="grid lg:grid-cols-2 gap-6">
              {data.stocks?.categories?.map((category: any, idx: number) => (
                <div key={idx} className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
                  <div className="flex items-center gap-2 mb-4">
                    <BarChart3 className={`w-5 h-5 ${darkMode ? 'text-blue-400' : 'text-blue-600'}`} />
                    <h3 className="font-semibold text-lg">{category.name}</h3>
                  </div>
                  <div className="space-y-3">
                    {category.stocks.map((stock: any, i: number) => (
                      <div key={i} className={`p-4 rounded-lg ${darkMode ? 'bg-slate-700/50' : 'bg-gray-100'} hover:opacity-80 transition-opacity`}>
                        <div className="flex items-center justify-between">
                          <div>
                            <div className="flex items-center gap-2">
                              <span className="font-bold text-lg">{stock.symbol}</span>
                              <span className={`text-xs px-2 py-0.5 rounded ${darkMode ? 'bg-slate-600 text-gray-300' : 'bg-gray-200 text-gray-600'}`}>
                                {stock.name}
                              </span>
                            </div>
                            <p className="text-sm text-gray-500 mt-1">
                              Vol: {(stock.volume / 1000000).toFixed(1)}M
                            </p>
                          </div>
                          <div className="text-right">
                            <p className="font-bold text-xl">${stock.price.toFixed(2)}</p>
                            <div className={`flex items-center gap-1 justify-end ${stock.changePercent >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                              {stock.changePercent >= 0 ? (
                                <TrendingUp className="w-4 h-4" />
                              ) : (
                                <TrendingDown className="w-4 h-4" />
                              )}
                              <span className="font-semibold">
                                {stock.changePercent >= 0 ? '+' : ''}{stock.changePercent.toFixed(2)}%
                              </span>
                            </div>
                            <p className={`text-sm ${stock.change >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                              {stock.change >= 0 ? '+' : ''}${stock.change.toFixed(2)}
                            </p>
                          </div>
                        </div>
                        {/* Mini sparkline bar */}
                        <div className="mt-3 flex items-center gap-2">
                          <div className={`flex-1 h-2 rounded-full ${darkMode ? 'bg-slate-600' : 'bg-gray-300'} overflow-hidden`}>
                            <div 
                              className={`h-full rounded-full ${stock.changePercent >= 0 ? 'bg-gradient-to-r from-green-500 to-green-400' : 'bg-gradient-to-r from-red-500 to-red-400'}`}
                              style={{ width: `${Math.min(Math.abs(stock.changePercent) * 5, 100)}%` }}
                            />
                          </div>
                          <Activity className={`w-4 h-4 ${stock.changePercent >= 0 ? 'text-green-500' : 'text-red-500'}`} />
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Section>

        {/* REDDIT RADAR */}
        <Section title="👽 Reddit Radar — Your Communities" darkMode={darkMode}>
          <div className="grid md:grid-cols-2 gap-6">
            {data.reddit.slice(0, 4).map((sub: any, i: number) => (
              <div key={i} className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'} border-l-4 border-orange-500`}>
                <div className="flex items-center gap-2 mb-4">
                  <span className="text-2xl">👽</span>
                  <span className="font-bold text-xl">r/{sub.subreddit}</span>
                </div>
                <div className="space-y-3">
                  {sub.posts.map((post: any, j: number) => (
                    <a key={j} href={post.url} target="_blank" rel="noopener noreferrer" className={`block p-4 rounded-lg hover:opacity-80 transition-opacity ${darkMode ? 'bg-slate-700/50' : 'bg-gray-100'}`}>
                      <p className="font-semibold text-base text-blue-400 hover:underline mb-2">{post.title}</p>
                      <div className="flex items-center gap-4 text-sm text-gray-500">
                        <span>⬆️ {post.score.toLocaleString()}</span>
                        <span>💬 {post.comments} comments</span>
                      </div>
                    </a>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </Section>

        {/* BLUESKY FEED */}
        <Section title="🦋 Bluesky — Your Feed" darkMode={darkMode}>
          <div className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
            <div className="flex items-center justify-between mb-4">
              <div>
                <span className="text-lg font-semibold">@{data.bluesky.handle}</span>
                <p className="text-sm text-gray-500">Following {data.bluesky.followsCount || 351} accounts</p>
              </div>
              <div className="flex gap-2">
                <a href={data.bluesky.feedUrl || `https://bsky.app/profile/${data.bluesky.handle}/follows`} target="_blank" rel="noopener noreferrer" className="px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg text-sm font-semibold">View Timeline</a>
                <a href={data.bluesky.profileUrl} target="_blank" rel="noopener noreferrer" className="px-4 py-2 border border-gray-600 hover:bg-gray-700 rounded-lg text-sm">Profile</a>
              </div>
            </div>
            
            <div className={`p-4 rounded-lg ${darkMode ? 'bg-slate-700/30' : 'bg-gray-50'}`}>
              <p className="text-base">{data.bluesky.summary}</p>
              {data.bluesky.note && (
                <p className="text-sm text-gray-500 mt-2">{data.bluesky.note}</p>
              )}
            </div>
            
            <div className="mt-4 text-center">
              <a href={data.bluesky.feedUrl || `https://bsky.app/profile/${data.bluesky.handle}/follows`} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-2 text-blue-400 hover:underline">
                <span>See what your follows are posting</span>
                <span>→</span>
              </a>
            </div>
          </div>
        </Section>

        {/* VIRAL PULSE */}
        <Section title="🔥 Viral Pulse — What's Breaking the Internet" darkMode={darkMode}>
          <div className="grid md:grid-cols-2 gap-6">
            {data.viral.map((trend: any, i: number) => (
              <div key={i} className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'} border-l-4 ${trend.category === 'MEMES' ? 'border-purple-500' : trend.category === 'TIKTOK' ? 'border-pink-500' : trend.category === 'X/TWITTER' ? 'border-blue-500' : 'border-yellow-500'}`}>
                <div className="flex items-center gap-3 mb-4">
                  <span className="text-3xl">{trend.icon}</span>
                  <span className="font-bold text-xl">{trend.topic}</span>
                </div>
                <div className="space-y-3">
                  {trend.content.map((item: any, j: number) => (
                    <a key={j} href={item.url} target="_blank" rel="noopener noreferrer" className={`block p-4 rounded-lg hover:opacity-80 transition-opacity ${darkMode ? 'bg-slate-700/50' : 'bg-gray-100'}`}>
                      <div className="flex items-start justify-between gap-3 mb-2">
                        <p className="font-semibold text-base text-blue-400 hover:underline">{item.headline}</p>
                        <span className={`text-sm px-3 py-1 rounded whitespace-nowrap ${darkMode ? 'bg-slate-600 text-gray-300' : 'bg-gray-200 text-gray-600'}`}>{item.platform}</span>
                      </div>
                      <p className={`text-base ${darkMode ? 'text-gray-400' : 'text-gray-600'}`}>{item.detail}</p>
                    </a>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </Section>

        {/* AI STRATEGY */}
        <Section title="🧠 AI Life Strategy & Analysis" darkMode={darkMode}>
          <div className="space-y-6">
            <div className={`p-6 rounded-xl ${darkMode ? 'bg-gradient-to-r from-slate-800 to-slate-700' : 'bg-gradient-to-r from-gray-100 to-gray-50'} border-l-4 border-blue-500`}>
              <h3 className="font-semibold text-xl mb-3 text-blue-400">⚡ Strategic Assessment</h3>
              <p className={`text-lg leading-relaxed ${darkMode ? 'text-gray-300' : 'text-gray-700'}`}>{data.strategy.strategicAssessment}</p>
            </div>
            
            <div className="grid md:grid-cols-2 gap-6">
              <div className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'} border-l-4 border-yellow-500`}>
                <h3 className="font-semibold text-xl mb-4">⚠️ Blindspots</h3>
                <ul className="space-y-3">
                  {data.strategy.blindspots.slice(0, 3).map((spot: string, i: number) => (
                    <li key={i} className={`text-base ${darkMode ? 'text-gray-300' : 'text-gray-600'}`}>{spot}</li>
                  ))}
                </ul>
              </div>
              <div className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'} border-l-4 border-green-500`}>
                <h3 className="font-semibold text-xl mb-4">🎯 Opportunities</h3>
                <ul className="space-y-3">
                  {data.strategy.opportunities.slice(0, 3).map((opp: string, i: number) => (
                    <li key={i} className={`text-base ${darkMode ? 'text-gray-300' : 'text-gray-600'}`}>{opp}</li>
                  ))}
                </ul>
              </div>
            </div>

            <div className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800/50' : 'bg-gray-100'}`}>
              <h3 className="font-semibold text-xl mb-3">🧩 Pattern Analysis</h3>
              <p className={`text-lg leading-relaxed ${darkMode ? 'text-gray-400' : 'text-gray-700'}`}>{data.strategy.patternAnalysis}</p>
            </div>
          </div>
        </Section>
      </main>
    </div>
  );
}

function Section({ title, children, darkMode }: { title: string; children: React.ReactNode; darkMode: boolean }) {
  return (
    <div className={`rounded-2xl overflow-hidden shadow-lg ${darkMode ? 'bg-slate-800/50' : 'bg-white'}`}>
      <div className="px-6 py-5 border-b border-gray-700/30">
        <h2 className="text-2xl font-bold">{title}</h2>
      </div>
      <div className="p-6">{children}</div>
    </div>
  );
}

function InsightBox({ title, color, children, darkMode }: { title: string; color: string; children: React.ReactNode; darkMode: boolean }) {
  const colors: any = { blue: 'border-blue-500', yellow: 'border-yellow-500', green: 'border-green-500', red: 'border-red-500', orange: 'border-orange-500', purple: 'border-purple-500' };
  return (
    <div className={`p-5 rounded-xl border-l-4 ${colors[color]} ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
      <h3 className={`font-semibold text-lg mb-2 text-${color}-400`}>{title}</h3>
      <div className={`text-base leading-relaxed ${darkMode ? 'text-gray-300' : 'text-gray-700'}`}>{children}</div>
    </div>
  );
}

// Format time helper
function formatTime(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  });
}

// Format duration helper
function formatDuration(minutes: number): string {
  if (minutes < 60) {
    return `${minutes} min`;
  }
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  if (mins === 0) {
    return `${hours} hr${hours > 1 ? 's' : ''}`;
  }
  return `${hours} hr${hours > 1 ? 's' : ''} ${mins} min`;
}

// Calendar Section Component
function CalendarSection({ calendar, darkMode, onDisconnect }: { calendar: CalendarData; darkMode: boolean; onDisconnect?: () => void }) {
  const [authLoading, setAuthLoading] = useState(false);

  const handleConnect = async () => {
    setAuthLoading(true);
    try {
      const res = await fetch('/api/calendar/auth');
      const data = await res.json();
      if (data.authUrl) {
        window.location.href = data.authUrl;
      } else {
        alert(data.error || 'Failed to get auth URL');
      }
    } catch (err) {
      alert('Failed to initiate authentication');
    } finally {
      setAuthLoading(false);
    }
  };

  // Not connected state
  if (!calendar.connected) {
    return (
      <Section title="📅 Schedule — Your Calendar" darkMode={darkMode}>
        <div className={`p-8 rounded-xl text-center ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
          <div className="mb-4">
            <CalendarIcon className={`w-16 h-16 mx-auto mb-4 ${darkMode ? 'text-gray-600' : 'text-gray-400'}`} />
            <h3 className="text-xl font-semibold mb-2">Connect Your Calendar</h3>
            <p className={`max-w-md mx-auto ${darkMode ? 'text-gray-400' : 'text-gray-600'}`}>
              {calendar.error || 'Link your Google Calendar to see today and tomorrow\'s events, video calls, and schedule at a glance.'}
            </p>
          </div>
          <button
            onClick={handleConnect}
            disabled={authLoading}
            className="px-6 py-3 bg-blue-500 hover:bg-blue-600 disabled:bg-gray-500 text-white rounded-lg font-semibold transition-colors flex items-center gap-2 mx-auto"
          >
            {authLoading ? (
              <>
                <RefreshCw className="w-5 h-5 animate-spin" />
                Connecting...
              </>
            ) : (
              <>
                <ExternalLink className="w-5 h-5" />
                Connect Google Calendar
              </>
            )}
          </button>
        </div>
      </Section>
    );
  }

  const todayEvents = calendar.today?.events || [];
  const tomorrowEvents = calendar.tomorrow?.events || [];
  const todayDate = calendar.today?.date ? new Date(calendar.today.date).toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' }) : 'Today';
  const tomorrowDate = calendar.tomorrow?.date ? new Date(calendar.tomorrow.date).toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' }) : 'Tomorrow';

  return (
    <Section title="📅 Schedule — Your Calendar" darkMode={darkMode}>
      <div className="grid lg:grid-cols-2 gap-6">
        {/* Today */}
        <div className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-lg flex items-center gap-2">
              <span className="w-3 h-3 rounded-full bg-blue-500"></span>
              {todayDate}
            </h3>
            <span className={`text-sm px-3 py-1 rounded-full ${darkMode ? 'bg-blue-500/20 text-blue-400' : 'bg-blue-100 text-blue-600'}`}>
              {todayEvents.length} events
            </span>
          </div>
          
          {todayEvents.length === 0 ? (
            <div className={`p-6 text-center rounded-lg ${darkMode ? 'bg-slate-700/30' : 'bg-gray-100'}`}>
              <p className={darkMode ? 'text-gray-400' : 'text-gray-600'}>No events scheduled for today</p>
            </div>
          ) : (
            <div className="space-y-3">
              {todayEvents.map((event) => (
                <EventCard key={event.id} event={event} darkMode={darkMode} />
              ))}
            </div>
          )}
        </div>

        {/* Tomorrow */}
        <div className={`p-6 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-white'}`}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-lg flex items-center gap-2">
              <span className="w-3 h-3 rounded-full bg-purple-500"></span>
              {tomorrowDate}
            </h3>
            <span className={`text-sm px-3 py-1 rounded-full ${darkMode ? 'bg-purple-500/20 text-purple-400' : 'bg-purple-100 text-purple-600'}`}>
              {tomorrowEvents.length} events
            </span>
          </div>
          
          {tomorrowEvents.length === 0 ? (
            <div className={`p-6 text-center rounded-lg ${darkMode ? 'bg-slate-700/30' : 'bg-gray-100'}`}>
              <p className={darkMode ? 'text-gray-400' : 'text-gray-600'}>No events scheduled for tomorrow</p>
            </div>
          ) : (
            <div className="space-y-3">
              {tomorrowEvents.map((event) => (
                <EventCard key={event.id} event={event} darkMode={darkMode} />
              ))}
            </div>
          )}
        </div>
      </div>
      
      {/* Disconnect button */}
      {onDisconnect && (
        <div className="mt-4 text-right">
          <button
            onClick={onDisconnect}
            className={`text-sm px-4 py-2 rounded-lg transition-colors ${
              darkMode 
                ? 'text-gray-400 hover:text-white hover:bg-slate-700' 
                : 'text-gray-500 hover:text-gray-900 hover:bg-gray-200'
            }`}
          >
            Disconnect Calendar
          </button>
        </div>
      )}
    </Section>
  );
}

// Event Card Component
function EventCard({ event, darkMode }: { event: CalendarEvent; darkMode: boolean }) {
  const isHappeningNow = () => {
    const now = new Date();
    const start = new Date(event.start);
    const end = new Date(event.end);
    return now >= start && now <= end;
  };

  const happeningNow = isHappeningNow();

  return (
    <div className={`p-4 rounded-lg border-l-4 transition-all ${
      happeningNow 
        ? 'border-green-500 ' + (darkMode ? 'bg-green-900/20' : 'bg-green-50') 
        : 'border-blue-500 ' + (darkMode ? 'bg-slate-700/50' : 'bg-gray-100')
    }`}>
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          <h4 className="font-semibold text-base truncate" title={event.title}>
            {event.title}
          </h4>
          
          <div className="flex flex-wrap items-center gap-3 mt-2 text-sm">
            {/* Time */}
            <div className={`flex items-center gap-1 ${darkMode ? 'text-gray-400' : 'text-gray-600'}`}>
              <Clock className="w-4 h-4" />
              {event.isAllDay ? (
                <span>All day</span>
              ) : (
                <span>
                  {formatTime(event.start)} - {formatTime(event.end)}
                  <span className="ml-2 text-xs opacity-70">({formatDuration(event.duration)})</span>
                </span>
              )}
            </div>
            
            {happeningNow && (
              <span className="text-xs px-2 py-0.5 rounded bg-green-500 text-white font-medium">
                NOW
              </span>
            )}
          </div>
          
          {/* Location */}
          {event.location && (
            <div className={`flex items-center gap-1 mt-2 text-sm ${darkMode ? 'text-gray-400' : 'text-gray-600'}`}>
              <LocationIcon className="w-4 h-4" />
              <span className="truncate">{event.location}</span>
            </div>
          )}
          
          {/* Attendees */}
          {event.attendees && event.attendees.length > 0 && (
            <div className={`flex items-center gap-1 mt-1 text-xs ${darkMode ? 'text-gray-500' : 'text-gray-500'}`}>
              <span>{event.attendees.length} attendee{event.attendees.length > 1 ? 's' : ''}</span>
            </div>
          )}
        </div>
        
        {/* Meet Link */}
        {event.meetLink && (
          <a
            href={event.meetLink}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1 px-3 py-1.5 bg-blue-500 hover:bg-blue-600 text-white rounded-lg text-sm font-medium transition-colors whitespace-nowrap"
          >
            <Video className="w-4 h-4" />
            Join
          </a>
        )}
      </div>
    </div>
  );
}