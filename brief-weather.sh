#!/bin/bash
set -euo pipefail
export TZ="America/New_York"

escape_html() {
  python3 -c 'import html,sys; print(html.escape(sys.stdin.read()), end="")'
}

WEATHER_JSON=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=40.3573&longitude=-74.6672&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max&forecast_days=3&timezone=America%2FNew_York")
TEMP=$(echo "$WEATHER_JSON" | jq -r '.current.temperature_2m // 0')
FEELS_LIKE=$(echo "$WEATHER_JSON" | jq -r '.current.apparent_temperature // 0')
WIND_KMH=$(echo "$WEATHER_JSON" | jq -r '.current.wind_speed_10m // 0')
TODAY_HIGH_C=$(echo "$WEATHER_JSON" | jq -r '.daily.temperature_2m_max[0] // 0')
TODAY_LOW_C=$(echo "$WEATHER_JSON" | jq -r '.daily.temperature_2m_min[0] // 0')
TOMORROW_HIGH_C=$(echo "$WEATHER_JSON" | jq -r '.daily.temperature_2m_max[1] // 0')
TOMORROW_LOW_C=$(echo "$WEATHER_JSON" | jq -r '.daily.temperature_2m_min[1] // 0')
TOMORROW_PRECIP=$(echo "$WEATHER_JSON" | jq -r '.daily.precipitation_probability_max[1] // 0')
TEMP_F=$(echo "scale=0; ($TEMP * 9/5) + 32" | bc -l 2>/dev/null | cut -d. -f1)
FEELS_F=$(echo "scale=0; ($FEELS_LIKE * 9/5) + 32" | bc -l 2>/dev/null | cut -d. -f1)
TODAY_HIGH_F=$(echo "scale=0; ($TODAY_HIGH_C * 9/5) + 32" | bc -l 2>/dev/null | cut -d. -f1)
TODAY_LOW_F=$(echo "scale=0; ($TODAY_LOW_C * 9/5) + 32" | bc -l 2>/dev/null | cut -d. -f1)
TOMORROW_HIGH_F=$(echo "scale=0; ($TOMORROW_HIGH_C * 9/5) + 32" | bc -l 2>/dev/null | cut -d. -f1)
TOMORROW_LOW_F=$(echo "scale=0; ($TOMORROW_LOW_C * 9/5) + 32" | bc -l 2>/dev/null | cut -d. -f1)
WIND_MPH=$(echo "scale=0; $WIND_KMH * 0.621371" | bc -l 2>/dev/null | cut -d. -f1)

if [ "$WIND_MPH" -ge 18 ] 2>/dev/null; then
  WEATHER_CALL="Windy enough to be annoying."
elif [ "$TOMORROW_PRECIP" -ge 60 ] 2>/dev/null; then
  WEATHER_CALL="Tomorrow has real rain risk."
else
  WEATHER_CALL="Nothing weather-wise should get in your way."
fi

SUMMARY="$WEATHER_CALL"

cat <<HTML
<section class="card">
  <h2>Weather / Logistics</h2>
  <ul>
    <li>Now: ${TEMP_F}°F, feels like ${FEELS_F}°F.</li>
    <li>Today: ${TODAY_HIGH_F}° / ${TODAY_LOW_F}°.</li>
    <li>Tomorrow: ${TOMORROW_HIGH_F}° / ${TOMORROW_LOW_F}°, rain risk ${TOMORROW_PRECIP}%.</li>
    <li>${WEATHER_CALL}</li>
  </ul>
</section>
HTML

echo "__SUMMARY__$(printf '%s' "$SUMMARY" | escape_html)"
