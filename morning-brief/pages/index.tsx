'use client';

import { useState, useEffect } from 'react';
import { Cloud, Trophy, TrendingUp, DollarSign, Flame, Brain, RefreshCw, Moon, Sun, Wind, Droplets, Globe, MapPin } from 'lucide-react';

interface BriefingData {
  weather: any;
  arsenal: any;
  crypto: any;
  tradfi: any;
  reddit: any[];
  bluesky: any;
  viral: any[];
  strategy: any;
  meta: any;
}

export default function Dashboard() {
  const [data, setData] = useState<BriefingData | null>(null);
  const [loading, setLoading] = useState(true);
  const [darkMode, setDarkMode] = useState(true);

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 300000);
    return () => clearInterval(interval);
  }, []);

  const fetchData = async () => {
    try {
      const res = await fetch('/api/briefing');
      const json = await res.json();
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