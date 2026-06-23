#!/bin/sh
# Waybar module: Services toggle with status tooltip
# Shows quick services status summary

# Tailscale status
get_tailscale_status() {
    if ! command -v tailscale >/dev/null 2>&1; then
        echo "N/A"
        return
    fi
    
    STATUS=$(tailscale status --json 2>/dev/null)
    if [ -z "$STATUS" ]; then
        echo "Down"
        return
    fi
    
    BACKEND_STATE=$(echo "$STATUS" | jq -r '.BackendState // "Unknown"')
    LOGGED_IN=$(echo "$STATUS" | jq -r '.Self.Online // false')
    
    if [ "$BACKEND_STATE" = "Running" ] && [ "$LOGGED_IN" = "true" ]; then
        echo "Up"
    else
        echo "Down"
    fi
}

# Cobalto status (quick check)
get_cobalto_status() {
    RESULT=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://cobalto.minerales.network:8096/" 2>/dev/null)
    
    case "$RESULT" in
        200|204|301|302) echo "Up" ;;
        *) echo "Down" ;;
    esac
}

# Syncthing status (quick check)
get_syncthing_status() {
    CONFIG="$HOME/.local/state/syncthing/config.xml"
    API_KEY=$(grep -oP '(?<=<apikey>)[^<]+' "$CONFIG" 2>/dev/null)
    
    if [ -z "$API_KEY" ]; then
        echo "N/A"
        return
    fi
    
    PING=$(curl -s -H "X-API-Key: $API_KEY" --connect-timeout 2 http://localhost:8384/rest/system/ping 2>/dev/null)
    
    if echo "$PING" | grep -q '"ping"'; then
        echo "Up"
    else
        echo "Down"
    fi
}

TS=$(get_tailscale_status)
CO=$(get_cobalto_status)
SY=$(get_syncthing_status)

TOOLTIP="Services Status:\\n"
TOOLTIP="${TOOLTIP}  Tailscale: ${TS}\\n"
TOOLTIP="${TOOLTIP}  Cobalto: ${CO}\\n"
TOOLTIP="${TOOLTIP}  Syncthing: ${SY}"

# Output JSON for waybar
# Using gem icon (Font Awesome f3a5)
ICON=$(printf '\uf3a5')
echo "{\"text\":\"${ICON}\",\"tooltip\":\"${TOOLTIP}\",\"class\":\"normal\"}"
