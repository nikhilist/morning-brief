import type { NextApiRequest, NextApiResponse } from 'next';
import yahooFinance from 'yahoo-finance2';

// Stock categories with company names
const STOCK_CATEGORIES = {
  'AI / Infrastructure': [
    { symbol: 'NVDA', name: 'NVIDIA' },
    { symbol: 'VRT', name: 'Vertiv' },
    { symbol: 'ALAB', name: 'Astera Labs' },
    { symbol: 'AMAT', name: 'Applied Materials' },
  ],
  'Cybersecurity': [
    { symbol: 'CRWD', name: 'CrowdStrike' },
    { symbol: 'NBIS', name: 'NioCorp' },
  ],
  'Cloud / SaaS': [
    { symbol: 'NOW', name: 'ServiceNow' },
    { symbol: 'DOCN', name: 'DigitalOcean' },
    { symbol: 'RBRK', name: 'Rubrik' },
  ],
  'E-commerce / Tech': [
    { symbol: 'AMZN', name: 'Amazon' },
    { symbol: 'MELI', name: 'MercadoLibre' },
    { symbol: 'JMIA', name: 'Jumia' },
  ],
  'Semiconductors / Materials': [
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
  marketCap?: number;
  dayHigh?: number;
  dayLow?: number;
  previousClose?: number;
}

interface CategoryData {
  name: string;
  stocks: StockData[];
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
      fields: ['regularMarketPrice', 'regularMarketChange', 'regularMarketChangePercent', 'regularMarketVolume', 'marketCap', 'regularMarketDayHigh', 'regularMarketDayLow', 'regularMarketPreviousClose'],
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
      marketCap: quote.marketCap,
      dayHigh: quote.regularMarketDayHigh,
      dayLow: quote.regularMarketDayLow,
      previousClose: quote.regularMarketPreviousClose,
    };
  } catch (error) {
    console.error(`Failed to fetch ${symbol}:`, error);
    return null;
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

      for (const { symbol, name } of stocks) {
        const data = await fetchStockData(symbol, name);
        if (data) {
          categoryStocks.push(data);
          totalStocks++;
          if (data.changePercent > 0) gainers++;
          if (data.changePercent < 0) losers++;
          totalChange += data.changePercent;
        }
      }

      if (categoryStocks.length > 0) {
        categories.push({
          name: categoryName,
          stocks: categoryStocks,
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
