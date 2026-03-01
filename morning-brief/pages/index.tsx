'use client';

import { useState, useEffect } from 'react';
import { 
  Cloud, Trophy, TrendingUp, DollarSign, Flame, Brain, RefreshCw, 
  Moon, Sun, Wind, Droplets, BarChart3, TrendingDown, Activity, 
  Calendar as CalendarIcon, Clock, Video, MapPin, ExternalLink,
  ChevronRight, Sparkles, Target, AlertCircle, Zap
} from 'lucide-react';

// Types
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
}

interface CalendarData {
  today: { date: string; dayName: string; events: CalendarEvent[] };
  tomorrow: { date: string; dayName: string; events: CalendarEvent[] };
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
  meta: { generatedAt: string; version: string; insightsSource: string };
}

// Utility Components
const Card = ({ children, className = '', darkMode, onClick }: any) => (
  <div 
    onClick={onClick}
    className={`
      rounded-2xl border transition-all duration-300
      ${darkMode 
        ? 'bg-[#141419] border-[#252532] hover:border-[#353545]' 
        : 'bg-white border-[#E5E5EA] hover:border-[#D5D5DA]'
      }
      ${onClick ? 'cursor-pointer hover:scale-[1.01]' : ''}
      ${className}
    `}
  >
    {children}
  </div>
);

const Badge = ({ children, color = 'blue', darkMode }: any) => {
  const colorClasses = {
    green: darkMode ? 'bg-green-500/10 text-green-400 border-green-500/20' : 'bg-green-50 text-green-600 border-green-200',
    red: darkMode ? 'bg-red-500/10 text-red-400 border-red-500/20' : 'bg-red-50 text-red-600 border-red-200',
    blue: darkMode ? 'bg-blue-500/10 text-blue-400 border-blue-500/20' : 'bg-blue-50 text-blue-600 border-blue-200',
    yellow: darkMode ? 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20' : 'bg-yellow-50 text-yellow-600 border-yellow-200',
    purple: darkMode ? 'bg-purple-500/10 text-purple-400 border-purple-500/20' : 'bg-purple-50 text-purple-600 border-purple-200',
  };
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${colorClasses[color as keyof typeof colorClasses]}`}>
      {children}
    </span>
  );
};

// Loading Skeleton
const Skeleton = ({ darkMode }: { darkMode: boolean }) => (
  <div className={`min-h-screen ${darkMode ? 'bg-[#0A0A0F]' : 'bg-[#F8F8FA]'}`}>
    <div className="max-w-6xl mx-auto px-4 sm:px-6 py-8">
      <div className="animate-pulse space-y-6">
        <div className={`h-12 w-64 rounded-xl ${darkMode ? 'bg-[#1A1A22]' : 'bg-gray-200'}`} />
        <div className={`h-4 w-48 rounded ${darkMode ? 'bg-[#1A1A22]' : 'bg-gray-200'}`} />
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {[...Array(6)].map((_, i) => (
            <div key={i} className={`h-48 rounded-2xl ${darkMode ? 'bg-[#1A1A22]' : 'bg-gray-200'}`} />
          ))}
        </div>
      </div>
    </div>
  </div>
);

// Header Component
const Header = ({ darkMode, setDarkMode, lastUpdated, onRefresh, refreshing }: any) => {
  const now = new Date();
  const timeString = now.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  const dateString = now.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });

  return (
    <header className={`border-b transition-colors duration-300 ${
      darkMode ? 'bg-[#0A0A0F] border-[#252532]' : 'bg-[#F8F8FA] border-[#E5E5EA]'
    }`}>
      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#EF0107] to-[#8B0000] flex items-center justify-center shadow-lg shadow-red-500/20">
              <Sparkles className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className={`text-xl font-bold tracking-tight ${darkMode ? 'text-white' : 'text-gray-900'}`}>
                Morning Brief
              </h1>
              <p className={`text-sm ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                {dateString} · <span className="tabular-nums">{timeString}</span>
                {lastUpdated && (
                  <span className={`ml-2 text-xs ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>
                    (updated {lastUpdated})
                  </span>
                )}
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-2">
            <button
              onClick={onRefresh}
              disabled={refreshing}
              className={`p-2.5 rounded-xl transition-all duration-200 ${
                darkMode 
                  ? 'hover:bg-[#1A1A22] text-gray-400 hover:text-white' 
                  : 'hover:bg-gray-100 text-gray-500 hover:text-gray-900'
              } ${refreshing ? 'animate-spin' : ''}`}
            >
              <RefreshCw className="w-5 h-5" />
            </button>
            <button
              onClick={() => setDarkMode(!darkMode)}
              className={`p-2.5 rounded-xl transition-all duration-200 ${
                darkMode 
                  ? 'hover:bg-[#1A1A22] text-gray-400 hover:text-yellow-400' 
                  : 'hover:bg-gray-100 text-gray-500 hover:text-orange-500'
              }`}
            >
              {darkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
            </button>
          </div>
        </div>
      </div>
    </header>
  );
};

// Weather Section
const WeatherSection = ({ data, darkMode }: { data: any; darkMode: boolean }) => (
  <Card darkMode={darkMode} className="overflow-hidden">
    <div className="p-5">
      <div className="flex items-center gap-2 mb-4">
        <Cloud className={`w-4 h-4 ${darkMode ? 'text-blue-400' : 'text-blue-500'}`} />
        <span className={`text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
          Weather
        </span>
        <span className={`text-xs ${darkMode ? 'text-gray-600' : 'text-gray-400'}`}>Princeton, NJ</span>
      </div>
      
      <div className="flex items-end gap-2 mb-4">
        <span className={`text-5xl font-light tracking-tighter ${darkMode ? 'text-white' : 'text-gray-900'}`}>
          {data.temp}°
        </span>
        <div className={`pb-2 text-sm ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
          <p>H: {data.high}°  L: {data.low}°</p>
        </div>
      </div>
      
      <p className={`text-lg font-medium mb-4 ${darkMode ? 'text-white' : 'text-gray-900'}`}>
        {data.condition}
      </p>
      
      <div className="grid grid-cols-3 gap-3">
        <div className={`p-3 rounded-xl ${darkMode ? 'bg-[#0A0A0F]' : 'bg-gray-50'}`}>
          <Droplets className={`w-4 h-4 mb-1 ${darkMode ? 'text-blue-400' : 'text-blue-500'}`} />
          <p className={`text-xs ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>Humidity</p>
          <p className={`text-sm font-semibold ${darkMode ? 'text-white' : 'text-gray-900'}`}>{data.humidity}%</p>
        </div>
        <div className={`p-3 rounded-xl ${darkMode ? 'bg-[#0A0A0F]' : 'bg-gray-50'}`}>
          <Wind className={`w-4 h-4 mb-1 ${darkMode ? 'text-gray-400' : 'text-gray-500'}`} />
          <p className={`text-xs ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>Wind</p>
          <p className={`text-sm font-semibold ${darkMode ? 'text-white' : 'text-gray-900'}`}>{data.wind} mph</p>
        </div>
        <div className={`p-3 rounded-xl ${darkMode ? 'bg-[#0A0A0F]' : 'bg-gray-50'}`}>
          <Cloud className={`w-4 h-4 mb-1 ${darkMode ? 'text-gray-400' : 'text-gray-500'}`} />
          <p className={`text-xs ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>Rain</p>
          <p className={`text-sm font-semibold ${darkMode ? 'text-white' : 'text-gray-900'}`}>{data.precip}</p>
        </div>
      </div>
    </div>
  </Card>
);

// Arsenal Section
const ArsenalSection = ({ data, darkMode }: { data: any; darkMode: boolean }) => (
  <Card darkMode={darkMode} className="overflow-hidden">
    <div className="p-5">
      <div className="flex items-center gap-2 mb-4">
        <Trophy className="w-4 h-4 text-[#EF0107]" />
        <span className={`text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
          Arsenal
        </span>
      </div>
      
      {/* Last Match */}
      <div className={`p-4 rounded-xl mb-4 ${darkMode ? 'bg-[#EF0107]/10' : 'bg-red-50'} border ${darkMode ? 'border-[#EF0107]/20' : 'border-red-100'}`}>
        <p className={`text-xs font-medium mb-1 ${darkMode ? 'text-red-400' : 'text-red-600'}`}>Last Result</p>
        <p className={`text-3xl font-bold ${darkMode ? 'text-white' : 'text-gray-900'}`}>
          {data.lastMatch?.score || '-'}
        </p>
        <p className={`text-sm ${darkMode ? 'text-gray-400' : 'text-gray-600'}`}>
          vs {data.lastMatch?.opponent}
        </p>
      </div>
      
      {/* Upcoming */}
      <div className="space-y-2">
        <p className={`text-xs font-medium uppercase tracking-wider ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>Upcoming</p>
        {data.upcoming?.slice(0, 2).map((match: any, i: number) => (
          <div key={i} className={`flex items-center justify-between p-3 rounded-lg ${darkMode ? 'bg-[#0A0A0F]' : 'bg-gray-50'}`}>
            <div>
              <p className={`text-sm font-medium ${darkMode ? 'text-white' : 'text-gray-900'}`}>vs {match.opponent}</p>
              <p className={`text-xs ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>{match.competition}</p>
            </div>
            <span className={`text-xs ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>{match.date}</span>
          </div>
        ))}
      </div>
    </div>
    
    {/* News */}
    {data.trendingNews?.length > 0 && (
      <div className={`border-t ${darkMode ? 'border-[#252532]' : 'border-gray-100'}`}>
        <div className="p-4">
          <p className={`text-xs font-medium uppercase tracking-wider mb-3 ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>Latest News</p>
          <div className="space-y-2">
            {data.trendingNews.slice(0, 3).map((news: any, i: number) => (
              <a 
                key={i} 
                href={news.url} 
                target="_blank" 
                rel="noopener noreferrer"
                className={`block p-3 rounded-xl ${darkMode ? 'bg-[#0A0A0F] hover:bg-[#141419]' : 'bg-gray-50 hover:bg-gray-100'} transition-colors`}
              >
                <p className={`text-sm line-clamp-2 ${darkMode ? 'text-white' : 'text-gray-900'}`}>{news.title}</p>
                <p className={`text-xs mt-1 ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>{news.source}</p>
              </a>
            ))}
          </div>
        </div>
      </div>
    )}

    {/* Injuries */}
    {data.injuries?.length > 0 && (
      <div className={`border-t ${darkMode ? 'border-[#252532]' : 'border-gray-100'}`}>
        <div className="p-4">
          <p className={`text-xs font-medium uppercase tracking-wider mb-3 ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>Squad Status</p>
          <div className="space-y-2">
            {data.injuries.slice(0, 3).map((injury: any, i: number) => (
              <div key={i} className={`flex items-center justify-between p-2 rounded-lg ${darkMode ? 'bg-[#0A0A0F]' : 'bg-gray-50'}`}>
                <span className={`text-sm ${darkMode ? 'text-white' : 'text-gray-900'}`}>{injury.player}</span>
                <Badge color={injury.status === 'FIT' ? 'green' : injury.status === 'DOUBT' ? 'yellow' : 'red'} darkMode={darkMode}>
                  {injury.status}
                </Badge>
              </div>
            ))}
          </div>
        </div>
      </div>
    )}

    {/* Table */}
    <div className={`border-t ${darkMode ? 'border-[#252532]' : 'border-gray-100'}`}>
      <div className="p-4">
        <p className={`text-xs font-medium uppercase tracking-wider mb-3 ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>Table</p>
        <div className="space-y-1">
          {data.table?.slice(0, 5).map((team: any) => (
            <div 
              key={team.position} 
              className={`flex items-center justify-between py-1.5 px-2 rounded ${
                team.team?.includes('Arsenal') 
                  ? (darkMode ? 'bg-[#EF0107]/10' : 'bg-red-50') 
                  : ''
              }`}
            >
              <div className="flex items-center gap-3">
                <span className={`w-4 text-xs font-medium ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>{team.position}</span>
                <span className={`text-sm ${darkMode ? 'text-white' : 'text-gray-900'} ${team.team?.includes('Arsenal') ? 'font-semibold' : ''}`}>
                  {team.team}
                </span>
              </div>
              <span className={`text-xs font-medium ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>{team.points} pts</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  </Card>
);

// Crypto Section - uses stocks API data
const CryptoSection = ({ data, darkMode }: { data: any[]; darkMode: boolean }) => {
  if (!data?.length) return null;
  
  return (
    <Card darkMode={darkMode}>
      <div className="p-5">
        <div className="flex items-center gap-2 mb-4">
          <DollarSign className={`w-4 h-4 ${darkMode ? 'text-yellow-400' : 'text-yellow-600'}`} />
          <span className={`text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
            Crypto
          </span>
        </div>
        
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {data.map((coin: any) => (
            <div key={coin.symbol} className={`p-3 rounded-xl ${darkMode ? 'bg-[#0A0A0F]' : 'bg-gray-50'}`}>
              <div className="flex items-center gap-2 mb-2">
                <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold ${
                  coin.symbol.includes('BTC') ? 'bg-orange-500/20 text-orange-400' :
                  coin.symbol.includes('ETH') ? 'bg-blue-500/20 text-blue-400' :
                  coin.symbol.includes('SOL') ? 'bg-purple-500/20 text-purple-400' :
                  'bg-green-500/20 text-green-400'
                }`}>
                  {coin.symbol[0]}
                </div>
                <p className={`text-sm font-medium ${darkMode ? 'text-white' : 'text-gray-900'}`}>{coin.name}</p>
              </div>
              <div className="text-right">
                <p className={`text-sm font-semibold ${darkMode ? 'text-white' : 'text-gray-900'}`}>${coin.price.toLocaleString()}</p>
                <p className={`text-xs ${coin.changePercent >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                  {coin.changePercent >= 0 ? '+' : ''}{coin.changePercent.toFixed(2)}%
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </Card>
  );
};

// Stocks Section
const StocksSection = ({ data, darkMode }: { data: any; darkMode: boolean }) => {
  if (!data?.categories) return null;

  return (
    <Card darkMode={darkMode}>
      <div className="p-5">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <BarChart3 className={`w-4 h-4 ${darkMode ? 'text-blue-400' : 'text-blue-500'}`} />
            <span className={`text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
              Watchlist
            </span>
          </div>
          {data.summary && (
            <div className="flex items-center gap-2">
              <span className={`text-xs ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>
                {data.summary.gainers} ↑ {data.summary.losers} ↓
              </span>
              <Badge color={data.summary.avgChange >= 0 ? 'green' : 'red'} darkMode={darkMode}>
                {data.summary.avgChange >= 0 ? '+' : ''}{data.summary.avgChange.toFixed(2)}%
              </Badge>
            </div>
          )}
        </div>

        <div className="space-y-4">
          {data.categories.map((category: any) => (
            <div key={category.name} className={`p-4 rounded-xl ${darkMode ? 'bg-[#0A0A0F]' : 'bg-gray-50'}`}>
              <div className="flex items-center justify-between mb-3">
                <span className={`text-sm font-semibold ${darkMode ? 'text-white' : 'text-gray-900'}`}>{category.name}</span>
                {category.insight && (
                  <div className="flex items-center gap-2">
                    <span className={`text-xs ${category.insight.avgChange >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                      {category.insight.avgChange >= 0 ? '+' : ''}{category.insight.avgChange.toFixed(2)}%
                    </span>
                    <div className={`w-2 h-2 rounded-full ${
                      category.insight.trend === 'up' ? 'bg-green-500' :
                      category.insight.trend === 'down' ? 'bg-red-500' : 'bg-gray-500'
                    }`} />
                  </div>
                )}
              </div>

              {/* Macro Summary */}
              {category.insight?.summary && (
                <p className={`text-xs mb-3 ${darkMode ? 'text-gray-400' : 'text-gray-600'}`}>
                  {category.insight.summary}
                </p>
              )}

              {/* News */}
              {category.insight?.news && (
                <p className={`text-xs mb-3 line-clamp-2 ${darkMode ? 'text-gray-500' : 'text-gray-500'}`}>
                  📰 {category.insight.news}
                </p>
              )}

              {/* Stocks */}
              <div className="space-y-2">
                {category.stocks.map((stock: any) => (
                  <div key={stock.symbol} className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className={`text-sm font-medium ${darkMode ? 'text-white' : 'text-gray-900'}`}>{stock.symbol}</span>
                      <span className={`text-xs ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>{stock.name}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className={`text-sm ${darkMode ? 'text-white' : 'text-gray-900'}`}>${stock.price.toFixed(2)}</span>
                      <span className={`text-xs ${stock.changePercent >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                        {stock.changePercent >= 0 ? '+' : ''}{stock.changePercent.toFixed(1)}%
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </Card>
  );
};

// Calendar Section
const CalendarSection = ({ data, darkMode, onConnect }: { data: CalendarData; darkMode: boolean; onConnect: () => void }) => {
  if (!data.connected) {
    return (
      <Card darkMode={darkMode}>
        <div className="p-6 text-center">
          <CalendarIcon className={`w-12 h-12 mx-auto mb-3 ${darkMode ? 'text-gray-600' : 'text-gray-400'}`} />
          <p className={`text-sm font-medium mb-1 ${darkMode ? 'text-white' : 'text-gray-900'}`}>Connect Calendar</p>
          <p className={`text-xs mb-4 ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>Link Google Calendar to see your schedule</p>
          <button
            onClick={onConnect}
            className="px-4 py-2 bg-[#EF0107] hover:bg-[#8B0000] text-white rounded-lg text-sm font-medium transition-colors"
          >
            Connect
          </button>
        </div>
      </Card>
    );
  }

  const formatTime = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  };

  return (
    <Card darkMode={darkMode}>
      <div className="p-5">
        <div className="flex items-center gap-2 mb-4">
          <CalendarIcon className={`w-4 h-4 ${darkMode ? 'text-purple-400' : 'text-purple-500'}`} />
          <span className={`text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
            Schedule
          </span>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Today */}
          <div>
            <p className={`text-xs font-medium mb-2 ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>Today</p>
            {data.today?.events?.length === 0 ? (
              <p className={`text-sm ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>No events</p>
            ) : (
              <div className="space-y-2">
                {data.today?.events?.slice(0, 3).map((event) => (
                  <div key={event.id} className={`p-3 rounded-xl ${darkMode ? 'bg-[#0A0A0F]' : 'bg-gray-50'}`}>
                    <div className="flex items-start justify-between gap-2">
                      <div className="min-w-0">
                        <p className={`text-sm font-medium truncate ${darkMode ? 'text-white' : 'text-gray-900'}`}>{event.title}</p>
                        <p className={`text-xs ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>
                          {formatTime(event.start)} · {event.duration} min
                        </p>
                      </div>
                      {event.meetLink && (
                        <a href={event.meetLink} target="_blank" rel="noopener noreferrer" className="shrink-0">
                          <Video className={`w-4 h-4 ${darkMode ? 'text-blue-400' : 'text-blue-500'}`} />
                        </a>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
          
          {/* Tomorrow */}
          <div>
            <p className={`text-xs font-medium mb-2 ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>Tomorrow</p>
            {data.tomorrow?.events?.length === 0 ? (
              <p className={`text-sm ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>No events</p>
            ) : (
              <div className="space-y-2">
                {data.tomorrow?.events?.slice(0, 3).map((event) => (
                  <div key={event.id} className={`p-3 rounded-xl ${darkMode ? 'bg-[#0A0A0F]' : 'bg-gray-50'}`}>
                    <p className={`text-sm font-medium truncate ${darkMode ? 'text-white' : 'text-gray-900'}`}>{event.title}</p>
                    <p className={`text-xs ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>
                      {formatTime(event.start)} · {event.duration} min
                    </p>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </Card>
  );
};

// Reddit Section
const RedditSection = ({ data, darkMode }: { data: any[]; darkMode: boolean }) => {
  if (!data?.length) return null;

  return (
    <Card darkMode={darkMode}>
      <div className="p-5">
        <div className="flex items-center gap-2 mb-4">
          <Flame className={`w-4 h-4 ${darkMode ? 'text-orange-400' : 'text-orange-500'}`} />
          <span className={`text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
            Reddit Radar
          </span>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {data.slice(0, 4).map((sub) => (
            <div key={sub.subreddit}>
              <div className="flex items-center gap-2 mb-2">
                <span className="text-xs">👽</span>
                <span className={`text-xs font-medium ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>r/{sub.subreddit}</span>
              </div>
              <div className="space-y-2">
                {sub.posts.slice(0, 2).map((post: any, i: number) => (
                  <a 
                    key={i} 
                    href={post.url} 
                    target="_blank" 
                    rel="noopener noreferrer"
                    className={`block p-3 rounded-xl ${darkMode ? 'bg-[#0A0A0F] hover:bg-[#141419]' : 'bg-gray-50 hover:bg-gray-100'} transition-colors`}
                  >
                    <p className={`text-sm line-clamp-2 ${darkMode ? 'text-white' : 'text-gray-900'}`}>{post.title}</p>
                    <div className={`flex items-center gap-3 mt-1 text-xs ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>
                      <span>⬆️ {post.score.toLocaleString()}</span>
                      <span>💬 {post.comments}</span>
                    </div>
                  </a>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </Card>
  );
};

// Bluesky Section
const BlueskySection = ({ data, darkMode }: { data: any; darkMode: boolean }) => {
  if (!data?.handle) return null;
  
  return (
    <Card darkMode={darkMode}>
      <div className="p-5">
        <div className="flex items-center gap-2 mb-4">
          <span className="text-lg">🦋</span>
          <span className={`text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
            Bluesky
          </span>
        </div>
        
        <div className={`p-4 rounded-xl ${darkMode ? 'bg-[#0A0A0F]' : 'bg-gray-50'} mb-4`}>
          <p className={`text-sm font-medium ${darkMode ? 'text-white' : 'text-gray-900'}`}>@{data.handle}</p>
          <p className={`text-xs ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>Following {data.followsCount} accounts</p>
        </div>
        
        <a 
          href={data.feedUrl || `https://bsky.app/profile/${data.handle}/follows`}
          target="_blank"
          rel="noopener noreferrer"
          className={`flex items-center justify-center gap-2 w-full py-2.5 rounded-xl text-sm font-medium transition-colors ${
            darkMode 
              ? 'bg-blue-500/10 text-blue-400 hover:bg-blue-500/20' 
              : 'bg-blue-50 text-blue-600 hover:bg-blue-100'
          }`}
        >
          View Timeline
          <ExternalLink className="w-4 h-4" />
        </a>
      </div>
    </Card>
  );
};

// Strategy Section
const StrategySection = ({ data, darkMode, insightsSource }: { data: any; darkMode: boolean; insightsSource: string }) => (
  <Card darkMode={darkMode}>
    <div className="p-5">
      <div className="flex items-center gap-2 mb-4">
        <Brain className={`w-4 h-4 ${darkMode ? 'text-purple-400' : 'text-purple-500'}`} />
        <span className={`text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
          Daily Intelligence
        </span>
        {insightsSource === 'llm' && (
          <Badge color="purple" darkMode={darkMode}>AI-Powered</Badge>
        )}
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div className={`p-4 rounded-xl ${darkMode ? 'bg-[#0A0A0F]' : 'bg-gray-50'}`}>
          <div className="flex items-center gap-2 mb-2">
            <Target className={`w-4 h-4 ${darkMode ? 'text-blue-400' : 'text-blue-500'}`} />
            <p className={`text-xs font-medium uppercase tracking-wider ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>Assessment</p>
          </div>
          <p className={`text-sm leading-relaxed ${darkMode ? 'text-gray-300' : 'text-gray-600'}`}>
            {data.strategicAssessment}
          </p>
        </div>
        
        <div className={`p-4 rounded-xl ${darkMode ? 'bg-[#0A0A0F]' : 'bg-gray-50'}`}>
          <div className="flex items-center gap-2 mb-2">
            <AlertCircle className={`w-4 h-4 ${darkMode ? 'text-yellow-400' : 'text-yellow-600'}`} />
            <p className={`text-xs font-medium uppercase tracking-wider ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>Watch For</p>
          </div>
          <ul className="space-y-1">
            {(data.blindspots || []).slice(0, 3).map((spot: string, i: number) => (
              <li key={i} className={`text-sm ${darkMode ? 'text-gray-300' : 'text-gray-600'}`}>{spot}</li>
            ))}
          </ul>
        </div>
        
        <div className={`p-4 rounded-xl ${darkMode ? 'bg-[#0A0A0F]' : 'bg-gray-50'}`}>
          <div className="flex items-center gap-2 mb-2">
            <Zap className={`w-4 h-4 ${darkMode ? 'text-green-400' : 'text-green-500'}`} />
            <p className={`text-xs font-medium uppercase tracking-wider ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>Opportunities</p>
          </div>
          <ul className="space-y-1">
            {(data.opportunities || []).slice(0, 3).map((opp: string, i: number) => (
              <li key={i} className={`text-sm ${darkMode ? 'text-gray-300' : 'text-gray-600'}`}>{opp}</li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  </Card>
);

// Main Dashboard
export default function Dashboard() {
  const [data, setData] = useState<BriefingData | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [darkMode, setDarkMode] = useState(true);
  const [calendarToken, setCalendarToken] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<string>('');

  // Handle OAuth callback
  useEffect(() => {
    if (typeof window === 'undefined') return;
    const urlParams = new URLSearchParams(window.location.search);
    const accessToken = urlParams.get('access_token');
    const connected = urlParams.get('calendar_connected');

    if (connected && accessToken) {
      localStorage.setItem('calendar_access_token', accessToken);
      setCalendarToken(accessToken);
      window.history.replaceState({}, document.title, window.location.pathname);
    } else {
      const stored = localStorage.getItem('calendar_access_token');
      if (stored) setCalendarToken(stored);
    }
  }, []);

  // Load dark mode preference
  useEffect(() => {
    if (typeof window === 'undefined') return;
    const saved = localStorage.getItem('darkMode');
    if (saved !== null) setDarkMode(saved === 'true');
  }, []);

  // Save dark mode preference
  useEffect(() => {
    if (typeof window === 'undefined') return;
    localStorage.setItem('darkMode', String(darkMode));
  }, [darkMode]);

  const fetchData = async () => {
    try {
      const res = await fetch('/api/briefing');
      if (!res.ok) throw new Error('API error');
      const json = await res.json();
      
      // Only fetch calendar if we have a token and are on client
      if (calendarToken && typeof window !== 'undefined') {
        try {
          const calRes = await fetch(`/api/calendar/events?access_token=${calendarToken}`);
          if (calRes.ok) {
            const calData = await calRes.json();
            json.calendar = calData;
          }
        } catch (e) {
          console.error('Calendar fetch failed:', e);
        }
      }
      
      setData(json);
      setLastUpdated(new Date().toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }));
    } catch (err) {
      console.error('Failed to fetch:', err);
      // Set fallback data so UI still renders
      setData({
        weather: { temp: 0, condition: 'Loading...', high: 0, low: 0, humidity: '0', wind: '0', precip: '0%', forecast: [], insights: { immediate: '', todayStrategy: '', tomorrowAnchor: '' } },
        arsenal: { lastMatch: { score: '-', opponent: '', headline: '' }, upcoming: [], injuries: [], trendingNews: [], table: [] },
        crypto: { prices: {}, sentiment: '', metrics: [], insights: { macroContext: '', smartMoneySignals: '', contrarianSetup: '' } },
        tradfi: { marketContext: {}, macroThemes: [] },
        reddit: [],
        bluesky: { handle: '', followsCount: 0 },
        viral: [],
        calendar: { today: { date: '', dayName: '', events: [] }, tomorrow: { date: '', dayName: '', events: [] }, connected: false },
        stocks: null,
        strategy: { strategicAssessment: '', blindspots: [], opportunities: [], patternAnalysis: '' },
        meta: { generatedAt: new Date().toISOString(), version: '3.2.0', insightsSource: 'template' }
      });
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 300000);
    return () => clearInterval(interval);
  }, [calendarToken]);

  const handleRefresh = () => {
    setRefreshing(true);
    fetchData();
  };

  const handleCalendarConnect = async () => {
    if (typeof window === 'undefined') return;
    try {
      const res = await fetch('/api/calendar/auth');
      const data = await res.json();
      if (data.authUrl) window.location.href = data.authUrl;
    } catch (err) {
      alert('Failed to connect calendar');
    }
  };

  if (loading) return <Skeleton darkMode={darkMode} />;
  if (!data) return null;

  return (
    <div className={`${darkMode ? 'bg-[#0A0A0F]' : 'bg-[#F8F8FA]'}`}>
      <Header
        darkMode={darkMode}
        setDarkMode={setDarkMode}
        lastUpdated={lastUpdated}
        onRefresh={handleRefresh}
        refreshing={refreshing}
      />

      <main className="max-w-6xl mx-auto px-4 sm:px-6 py-6 pb-24">
        <div className="space-y-4">
          {/* Row 1 - 3 columns */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <WeatherSection data={data.weather} darkMode={darkMode} />
            <ArsenalSection data={data.arsenal} darkMode={darkMode} />
            <BlueskySection data={data.bluesky} darkMode={darkMode} />
          </div>

          {/* Full width sections */}
          <CryptoSection data={data.stocks?.crypto} darkMode={darkMode} />
          <StocksSection data={data.stocks} darkMode={darkMode} />
          <RedditSection data={data.reddit} darkMode={darkMode} />
          <CalendarSection
            data={data.calendar}
            darkMode={darkMode}
            onConnect={handleCalendarConnect}
          />
          <StrategySection
            data={data.strategy}
            darkMode={darkMode}
            insightsSource={data.meta?.insightsSource || 'template'}
          />
        </div>
      </main>
    </div>
  );
}
