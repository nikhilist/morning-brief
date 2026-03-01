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
    <header className={`sticky top-0 z-50 backdrop-blur-xl border-b transition-colors duration-300 ${
      darkMode ? 'bg-[#0A0A0F]/80 border-[#252532]' : 'bg-[#F8F8FA]/80 border-[#E5E5EA]'
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

// Crypto Section
const CryptoSection = ({ data, darkMode }: { data: any; darkMode: boolean }) => (
  <Card darkMode={darkMode}>
    <div className="p-5">
      <div className="flex items-center gap-2 mb-4">
        <DollarSign className={`w-4 h-4 ${darkMode ? 'text-yellow-400' : 'text-yellow-600'}`} />
        <span className={`text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
          Crypto
        </span>
      </div>
      
      <div className="space-y-3">
        {Object.entries(data.prices || {}).map(([name, coin]: [string, any]) => (
          <div key={name} className={`flex items-center justify-between p-3 rounded-xl ${darkMode ? 'bg-[#0A0A0F]' : 'bg-gray-50'}`}>
            <div className="flex items-center gap-3">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold ${
                name === 'bitcoin' ? 'bg-orange-500/20 text-orange-400' :
                name === 'ethereum' ? 'bg-blue-500/20 text-blue-400' :
                'bg-purple-500/20 text-purple-400'
              }`}>
                {name[0].toUpperCase()}
              </div>
              <div>
                <p className={`text-sm font-medium capitalize ${darkMode ? 'text-white' : 'text-gray-900'}`}>{name}</p>
              </div>
            </div>
            <div className="text-right">
              <p className={`text-sm font-semibold ${darkMode ? 'text-white' : 'text-gray-900'}`}>{coin.price}</p>
              <p className={`text-xs ${coin.up ? 'text-green-400' : 'text-red-400'}`}>{coin.change}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  </Card>
);

// Stocks Section
const StocksSection = ({ data, darkMode }: { data: any; darkMode: boolean }) => {
  if (!data?.categories) return null;
  
  return (
    <Card darkMode={darkMode} className="lg:col-span-2">
      <div className="p-5">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <BarChart3 className={`w-4 h-4 ${darkMode ? 'text-blue-400' : 'text-blue-500'}`} />
            <span className={`text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
              Watchlist
            </span>
          </div>
          {data.summary && (
            <Badge color={data.summary.avgChange >= 0 ? 'green' : 'red'} darkMode={darkMode}>
              {data.summary.avgChange >= 0 ? '+' : ''}{data.summary.avgChange.toFixed(2)}%
            </Badge>
          )}
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {data.categories.slice(0, 2).map((category: any) => (
            <div key={category.name}>
              <p className={`text-xs font-medium mb-2 ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>{category.name}</p>
              <div className="space-y-2">
                {category.stocks.slice(0, 3).map((stock: any) => (
                  <div key={stock.symbol} className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className={`text-sm font-medium ${darkMode ? 'text-white' : 'text-gray-900'}`}>{stock.symbol}</span>
                      <span className={`text-xs ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>{stock.name}</span>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className={`text-sm font-medium ${darkMode ? 'text-white' : 'text-gray-900'}`}>${stock.price.toFixed(2)}</span>
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
    <Card darkMode={darkMode} className="lg:col-span-2">
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

// Strategy Section
const StrategySection = ({ data, darkMode, insightsSource }: { data: any; darkMode: boolean; insightsSource: string }) => (
  <Card darkMode={darkMode} className="lg:col-span-3">
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
    const saved = localStorage.getItem('darkMode');
    if (saved !== null) setDarkMode(saved === 'true');
  }, []);

  // Save dark mode preference
  useEffect(() => {
    localStorage.setItem('darkMode', String(darkMode));
  }, [darkMode]);

  const fetchData = async () => {
    try {
      const res = await fetch('/api/briefing');
      const json = await res.json();
      
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
      setLastUpdated(new Date().toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }));
    } catch (err) {
      console.error('Failed to fetch:', err);
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
    <div className={`min-h-screen transition-colors duration-500 ${darkMode ? 'bg-[#0A0A0F]' : 'bg-[#F8F8FA]'}`}>
      <Header 
        darkMode={darkMode} 
        setDarkMode={setDarkMode} 
        lastUpdated={lastUpdated}
        onRefresh={handleRefresh}
        refreshing={refreshing}
      />
      
      <main className="max-w-6xl mx-auto px-4 sm:px-6 py-6 pb-24">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {/* First Row */}
          <WeatherSection data={data.weather} darkMode={darkMode} />
          <ArsenalSection data={data.arsenal} darkMode={darkMode} />
          <CryptoSection data={data.crypto} darkMode={darkMode} />
          
          {/* Second Row - Wider Cards */}
          <StocksSection data={data.stocks} darkMode={darkMode} />
          <CalendarSection 
            data={data.calendar} 
            darkMode={darkMode} 
            onConnect={handleCalendarConnect}
          />
          
          {/* Third Row - Full Width Intelligence */}
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
