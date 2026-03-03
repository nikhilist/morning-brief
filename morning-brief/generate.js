#!/usr/bin/env node
/**
 * Morning Brief Generator
 * Runs at 6 AM ET, generates HTML brief, sends Telegram link
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const WORKSPACE = '/home/nik/.openclaw/workspace';
const OUTPUT_DIR = path.join(WORKSPACE, 'morning-brief');
const TOKENS_FILE = path.join(WORKSPACE, '.google-tokens.json');
const TODOIST_TOKEN_FILE = path.join(WORKSPACE, '.todoist-token.json');

// Telegram config - will be read from OpenClaw config
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

function log(msg) {
  console.log(`[morning-brief] ${msg}`);
}

function loadTokens() {
  const tokens = JSON.parse(fs.readFileSync(TOKENS_FILE, 'utf8'));
  return tokens.access_token;
}

function loadTodoistToken() {
  const data = JSON.parse(fs.readFileSync(TODOIST_TOKEN_FILE, 'utf8'));
  return data.token;
}

async function fetchCalendarEvents(accessToken, calendarId, calendarName) {
  const today = new Date();
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  
  const timeMin = today.toISOString();
  const timeMax = tomorrow.toISOString();
  
  const url = `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(calendarId)}/events?timeMin=${timeMin}&timeMax=${timeMax}&singleEvents=true&orderBy=startTime`;
  
  try {
    const response = await fetch(url, {
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });
    const data = await response.json();
    return {
      name: calendarName,
      events: data.items || []
    };
  } catch (err) {
    log(`Error fetching ${calendarName}: ${err.message}`);
    return { name: calendarName, events: [] };
  }
}

async function fetchGmailSummary(accessToken) {
  const url = 'https://www.googleapis.com/gmail/v1/users/me/messages?q=is:unread&maxResults=5';
  
  try {
    const response = await fetch(url, {
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });
    const data = await response.json();
    const count = data.messages ? data.messages.length : 0;
    return { unreadCount: count, messages: data.messages || [] };
  } catch (err) {
    log(`Error fetching Gmail: ${err.message}`);
    return { unreadCount: 0, messages: [] };
  }
}

async function fetchTodoistTasks(token) {
  const today = new Date().toISOString().split('T')[0];
  const url = `https://api.todoist.com/api/v1/tasks?filter=today`;
  
  try {
    const response = await fetch(url, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const data = await response.json();
    return data.results || [];
  } catch (err) {
    log(`Error fetching Todoist: ${err.message}`);
    return [];
  }
}

async function fetchWeather() {
  // Princeton, NJ coordinates
  const lat = 40.3573;
  const lon = -74.6672;
  
  try {
    const response = await fetch(`https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=America/New_York&forecast_days=1`);
    const data = await response.json();
    return data.daily;
  } catch (err) {
    log(`Error fetching weather: ${err.message}`);
    return null;
  }
}

function getWeatherEmoji(code) {
  // WMO Weather interpretation codes
  if (code === 0) return '☀️';
  if (code >= 1 && code <= 3) return '⛅';
  if (code >= 45 && code <= 48) return '🌫️';
  if (code >= 51 && code <= 67) return '🌧️';
  if (code >= 71 && code <= 77) return '🌨️';
  if (code >= 80 && code <= 82) return '🌧️';
  if (code >= 85 && code <= 86) return '🌨️';
  if (code >= 95 && code <= 99) return '⛈️';
  return '🌡️';
}

function formatEvent(event) {
  const start = event.start;
  if (start.dateTime) {
    const date = new Date(start.dateTime);
    const time = date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
    return { time, summary: event.summary, allDay: false };
  } else {
    return { time: 'All day', summary: event.summary, allDay: true };
  }
}

function generateHTML(data) {
  const today = new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });
  
  let html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Morning Brief - ${today}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #f5f5f5;
      padding: 20px;
      max-width: 600px;
      margin: 0 auto;
    }
    h1 {
      font-size: 24px;
      margin-bottom: 20px;
      color: #333;
    }
    .section {
      background: white;
      border-radius: 12px;
      padding: 16px;
      margin-bottom: 16px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }
    .section h2 {
      font-size: 14px;
      text-transform: uppercase;
      color: #666;
      margin-bottom: 12px;
      letter-spacing: 0.5px;
    }
    .weather {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .weather .temp {
      font-size: 32px;
      font-weight: 600;
    }
    .weather .emoji {
      font-size: 40px;
    }
    .event, .task {
      padding: 10px 0;
      border-bottom: 1px solid #eee;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .event:last-child, .task:last-child {
      border-bottom: none;
    }
    .event-time, .task-check {
      color: #666;
      font-size: 14px;
      min-width: 80px;
    }
    .event-title, .task-title {
      flex: 1;
      font-size: 15px;
    }
    .calendar-name {
      font-size: 12px;
      color: #999;
      background: #f0f0f0;
      padding: 2px 8px;
      border-radius: 12px;
    }
    .empty {
      color: #999;
      font-style: italic;
      padding: 10px 0;
    }
    .gmail-count {
      font-size: 18px;
      color: #333;
    }
    .gmail-count span {
      font-size: 32px;
      font-weight: 600;
      color: #ea4335;
    }
    .footer {
      text-align: center;
      color: #999;
      font-size: 12px;
      margin-top: 20px;
    }
  </style>
</head>
<body>
  <h1>📅 ${today}</h1>
  
  <div class="section">
    <h2>Weather - Princeton, NJ</h2>
    <div class="weather">
      <div class="emoji">${data.weather ? getWeatherEmoji(data.weather.weather_code[0]) : '🌡️'}</div>
      <div class="temp">${data.weather ? `${Math.round(data.weather.temperature_2m_max[0])}° / ${Math.round(data.weather.temperature_2m_min[0])}°` : 'N/A'}</div>
    </div>
  </div>

  <div class="section">
    <h2>Today's Events</h2>`;

  let hasEvents = false;
  for (const cal of data.calendars) {
    for (const event of cal.events) {
      hasEvents = true;
      const formatted = formatEvent(event);
      html += `
    <div class="event">
      <span class="event-time">${formatted.time}</span>
      <span class="event-title">${formatted.summary}</span>
      <span class="calendar-name">${cal.name}</span>
    </div>`;
    }
  }
  
  if (!hasEvents) {
    html += `
    <div class="empty">No events today</div>`;
  }

  html += `
  </div>

  <div class="section">
    <h2>Tasks</h2>`;

  if (data.tasks.length === 0) {
    html += `
    <div class="empty">No tasks for today</div>`;
  } else {
    for (const task of data.tasks) {
      html += `
    <div class="task">
      <span class="task-check">☐</span>
      <span class="task-title">${task.content}</span>
    </div>`;
    }
  }

  html += `
  </div>

  <div class="section">
    <h2>Gmail</h2>
    <div class="gmail-count">
      <span>${data.gmail.unreadCount}</span> unread messages
    </div>
  </div>

  <div class="footer">
    Generated at ${new Date().toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })}
  </div>
</body>
</html>`;

  return html;
}

async function main() {
  log('Starting morning brief generation...');
  
  const accessToken = loadTokens();
  const todoistToken = loadTodoistToken();
  
  // Fetch all data in parallel
  const [calendars, gmail, tasks, weather] = await Promise.all([
    Promise.all([
      fetchCalendarEvents(accessToken, 'nikhilist@gmail.com', 'Personal'),
      fetchCalendarEvents(accessToken, '8tdo49s92dr6h34pcros8a17k8@group.calendar.google.com', 'Family'),
      fetchCalendarEvents(accessToken, '08ac8665d76573fd7cfcb0e0cb13ed3a951e59b7b1c4c6eabc9adaae8a74e615@group.calendar.google.com', 'Arsenal')
    ]),
    fetchGmailSummary(accessToken),
    fetchTodoistTasks(todoistToken),
    fetchWeather()
  ]);
  
  const data = {
    calendars,
    gmail,
    tasks,
    weather
  };
  
  const html = generateHTML(data);
  const outputFile = path.join(OUTPUT_DIR, 'index.html');
  fs.writeFileSync(outputFile, html);
  
  log(`Brief saved to: ${outputFile}`);
  
  // Send Telegram notification with link
  // For now, just log the success. Telegram sending will be set up separately
  log('Brief generated successfully!');
  
  return outputFile;
}

main().catch(err => {
  log(`Error: ${err.message}`);
  process.exit(1);
});
