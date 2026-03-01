import type { NextApiRequest, NextApiResponse } from 'next';
import yf from 'yahoo-finance2';
const yahooFinance = yf.default;

const BRAVE_API_KEY = process.env.BRAVE_API_KEY?.trim();

// Stock categories reorganized as requested
const STOCK_CATEGORIES = {
  'AI Infrastructure': [
    { symbol: 'NVDA', name: 'NVIDIA' },
    { symbol: 'VRT', name: 'Vertiv' },
    { symbol: 'ALAB', name: 'Astera Labs' },
  ],
  'E-commerce': [
    { symbol: 'AMZN', name: 'Amazon' },
    { symbol: 'MELI', name: 'MercadoLibre' },
    { symbol: 'JMIA', name: 'Jumia' },
  ],
  'Big Tech': [
    { symbol: 'NOW', name: 'ServiceNow' },
    { symbol: 'CRWD', name: 'CrowdStrike' },
    { symbol: 'AMAT', name: 'Applied Materials' },
  ],
  'Software': [
    { symbol: 'DOCN', name: 'DigitalOcean' },
    { symbol: 'RBRK', name: 'Rubrik' },
  ],
  'Other': [
    { symbol: 'NBIS', name: 'NioCorp' },
    { symbol: 'SITM', name: 'SiTime' },
    { symbol: 'COPX', name: 'Global X Copper Miners ETF' },
  ],
};

interface StockData {
  symbol: string;
  name: string;
  price: number;
  change: number;
  changePercent: number;
  volume: number;
}

interface CategoryInsight {
  trend: 'up' | 'down' | 'neutral';
  avgChange: number;
  summary: string;
  news?: string;
}

interface CategoryData {
  name: string;
  stocks: StockData[];
  insight: CategoryInsight;
}

export interface StocksResponse {
  categories: CategoryData[];
  lastUpdated: string;
  summary: {
    totalStocks: number;
    gainers: number;
    losers: number;
    avgChange: number;
  };
}

async function fetchStockData(symbol: string, name: string): Promise<StockData | null> {
  try {
    const quote: any = await yahooFinance.quote(symbol, {
      fields: ['regularMarketPrice', 'regularMarketChange', 'regularMarketChangePercent', 'regularMarketVolume'],
    });

    if (!quote || typeof quote.regularMarketPrice !== 'number') {
      return null;
    }

    return {
      symbol,
      name,
      price: quote.regularMarketPrice,
      change: quote.regularMarketChange || 0,
      changePercent: quote.regularMarketChangePercent || 0,
      volume: quote.regularMarketVolume || 0,
    };
  } catch (error) {
    console.error(`Failed to fetch ${symbol}:`, error);
    return null;
  }
}

async function fetchCategoryNews(category: string): Promise<string> {
  if (!BRAVE_API_KEY) return '';
  
  try {
    const searchQueries: Record<string, string> = {
      'AI Infrastructure': 'AI infrastructure stocks NVIDIA Vertiv data centers news',
      'E-commerce': 'Amazon MercadoLibre e-commerce retail stocks news',
      'Big Tech': 'ServiceNow CrowdStrike cybersecurity enterprise tech news',
      'Software': 'cloud software SaaS stocks DigitalOcean Rubrik news',
      'Other': 'semiconductor materials copper mining stocks news',
    };
    
    const query = searchQueries[category] || `${category} stocks news`;
    
    const res = await fetch(
      `https://api.search.brave.com/res/v1/news/search?q=${encodeURIComponent(query)}&count=3`,
      {
        headers: { 
          'X-Subscription-Token': BRAVE_API_KEY, 
          'Accept': 'application/json' 
        },
      }
    );
    
    if (!res.ok) return '';
    
    const data = await res.json();
    const results = data.results || [];
    
    if (results.length > 0) {
      // Return the most relevant headline
      return results[0].title;
    }
    
    return '';
  } catch (e) {
    return '';
  }
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<StocksResponse | { error: string }>
) {
  try {
    const categories: CategoryData[] = [];
    let totalStocks = 0;
    let gainers = 0;
    let losers = 0;
    let totalChange = 0;

    // Fetch data for each category
    for (const [categoryName, stocks] of Object.entries(STOCK_CATEGORIES)) {
      const categoryStocks: StockData[] = [];
      let categoryChange = 0;

      for (const { symbol, name } of stocks) {
        const data = await fetchStockData(symbol, name);
        if (data) {
          categoryStocks.push(data);
          totalStocks++;
          categoryChange += data.changePercent;
          if (data.changePercent > 0) gainers++;
          if (data.changePercent < 0) losers++;
          totalChange += data.changePercent;
        }
      }

      if (categoryStocks.length > 0) {
        const avgChange = categoryChange / categoryStocks.length;
        const news = await fetchCategoryNews(categoryName);
        
        // Generate macro summary based on performance
        let summary = '';
        if (avgChange > 2) summary = 'Strong momentum driven by sector tailwinds';
        else if (avgChange > 0.5) summary = 'Positive sentiment with steady buying';
        else if (avgChange > -0.5) summary = 'Consolidating near recent levels';
        else if (avgChange > -2) summary = 'Facing pressure from broader market weakness';
        else summary = 'Sharp pullback on sector rotation concerns';
        
        categories.push({
          name: categoryName,
          stocks: categoryStocks,
          insight: {
            trend: avgChange > 0.5 ? 'up' : avgChange < -0.5 ? 'down' : 'neutral',
            avgChange,
            summary,
            news: news || undefined,
          },
        });
      }
    }

    const response: StocksResponse = {
      categories,
      lastUpdated: new Date().toISOString(),
      summary: {
        totalStocks,
        gainers,
        losers,
        avgChange: totalStocks > 0 ? totalChange / totalStocks : 0,
      },
    };

    // Cache for 5 minutes
    res.setHeader('Cache-Control', 'public, max-age=300, stale-while-revalidate=600');
    res.status(200).json(response);
  } catch (error) {
    console.error('Stock API error:', error);
    res.status(500).json({ error: 'Failed to fetch stock data' });
  }
}
