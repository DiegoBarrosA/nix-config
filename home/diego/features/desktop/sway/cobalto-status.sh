#!/bin/sh
# Waybar module: Cobalto server and Jellyfin status
# Checks server reachability via Tailscale and Jellyfin service health

COBALTO_HOST="cobalto.minerales.network"
JELLYFIN_PORT="8096"
TIMEOUT=3

# Server icon (f233)
ICON=$(printf '\uf233')

# First check if Tailscale is connected (quick check)
if ! tailscale status >/dev/null 2>&1; then
    echo "{\"text\":\"${ICON}\",\"tooltip\":\"Cobalto: Tailscale not running\",\"class\":\"offline\"}"
    exit 0
fi

# Check if Cobalto is reachable via Tailscale network
# Using curl instead of ping for more reliable cross-platform behavior
PING_RESULT=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$TIMEOUT" "http://${COBALTO_HOST}:${JELLYFIN_PORT}" 2>/dev/null)

if [ -z "$PING_RESULT" ] || [ "$PING_RESULT" = "000" ]; then
    # Server not reachable at all
    echo "{\"text\":\"${ICON}\",\"tooltip\":\"Cobalto: Server offline\",\"class\":\"offline\"}"
    exit 0
fi

# Server is reachable, now check Jellyfin health
# Jellyfin responds with 200 on the root endpoint when healthy
JELLYFIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$TIMEOUT" "http://${COBALTO_HOST}:${JELLYFIN_PORT}/health" 2>/dev/null)

# If /health doesn't exist, try the main page
if [ "$JELLYFIN_STATUS" = "404" ]; then
    JELLYFIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$TIMEOUT" "http://${COBALTO_HOST}:${JELLYFIN_PORT}/" 2>/dev/null)
fi

case "$JELLYFIN_STATUS" in
    200|204|301|302)
        echo "{\"text\":\"${ICON}\",\"tooltip\":\"Cobalto: Online\\nJellyfin: Running\",\"class\":\"ok\"}"
        ;;
    000)
        echo "{\"text\":\"${ICON}\",\"tooltip\":\"Cobalto: Online\\nJellyfin: Not responding\",\"class\":\"degraded\"}"
        ;;
    *)
        echo "{\"text\":\"${ICON}\",\"tooltip\":\"Cobalto: Online\\nJellyfin: Error (${JELLYFIN_STATUS})\",\"class\":\"degraded\"}"
        ;;
esac
