#!/bin/bash
set -euo pipefail
export TZ="America/New_York"

escape_html() {
  python3 -c 'import html,sys; print(html.escape(sys.stdin.read()), end="")'
}

WORKSPACE="/home/nik/.openclaw/workspace"
TRAVEL_CONTEXT_FILE="$WORKSPACE/travel-context.json"
DEFAULT_NAME="Princeton, NJ"
DEFAULT_LAT="40.3573"
DEFAULT_LON="-74.6672"
DEFAULT_TZ="America/New_York"

LOCATION_NAME="$DEFAULT_NAME"
LAT="$DEFAULT_LAT"
LON="$DEFAULT_LON"
WEATHER_TZ="$DEFAULT_TZ"
IS_TRAVEL="false"

if [ -f "$TRAVEL_CONTEXT_FILE" ]; then
  LOCATION_NAME=$(jq -r '.location_name // empty' "$TRAVEL_CONTEXT_FILE" 2>/dev/null || echo "$DEFAULT_NAME")
  LAT=$(jq -r '.latitude // empty' "$TRAVEL_CONTEXT_FILE" 2>/dev/null || echo "$DEFAULT_LAT")
  LON=$(jq -r '.longitude // empty' "$TRAVEL_CONTEXT_FILE" 2>/dev/null || echo "$DEFAULT_LON")
  WEATHER_TZ=$(jq -r '.timezone // empty' "$TRAVEL_CONTEXT_FILE" 2>/dev/null || echo "$DEFAULT_TZ")
  IS_TRAVEL=$(jq -r '.active // false' "$TRAVEL_CONTEXT_FILE" 2>/dev/null || echo "false")

  [ -n "$LOCATION_NAME" ] || LOCATION_NAME="$DEFAULT_NAME"
  [ -n "$LAT" ] || LAT="$DEFAULT_LAT"
  [ -n "$LON" ] || LON="$DEFAULT_LON"
  [ -n "$WEATHER_TZ" ] || WEATHER_TZ="$DEFAULT_TZ"
fi

FETCHED_AT=$(date -Iseconds)
ENC_TZ=$(python3 - <<'PY' "$WEATHER_TZ"
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1]))
PY
)

WEATHER_JSON=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max&forecast_days=3&timezone=${ENC_TZ}")
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

if [ "$IS_TRAVEL" = "true" ]; then
  SUMMARY="$LOCATION_NAME weather: $WEATHER_CALL"
  HEADER="Weather / Logistics — $LOCATION_NAME"
else
  SUMMARY="Home weather for $LOCATION_NAME: $WEATHER_CALL"
  HEADER="Weather / Logistics — Home Base ($LOCATION_NAME)"
fi

cat <<HTML
<section class="card">
  <h2>${HEADER}</h2>
  <ul>
    <li>Now: ${TEMP_F}°F, feels like ${FEELS_F}°F.</li>
    <li>Today: ${TODAY_HIGH_F}° / ${TODAY_LOW_F}°.</li>
    <li>Tomorrow: ${TOMORROW_HIGH_F}° / ${TOMORROW_LOW_F}°, rain risk ${TOMORROW_PRECIP}%.</li>
    <li>${WEATHER_CALL}</li>
  </ul>
</section>
HTML

echo "__SUMMARY__$(printf '%s' "$SUMMARY" | escape_html)"
echo "__FETCHED_AT__${FETCHED_AT}"
