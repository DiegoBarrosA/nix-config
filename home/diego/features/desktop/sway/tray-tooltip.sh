#!/bin/sh
# Waybar module: Tray toggle with combined status tooltip
# Shows services status + system resources in tooltip

# ============ Services Status ============

# Tailscale status
get_tailscale_status() {
    if ! command -v tailscale >/dev/null 2>&1; then
        echo "Not installed"
        return
    fi
    
    STATUS=$(tailscale status --json 2>/dev/null)
    if [ -z "$STATUS" ]; then
        echo "Not running"
        return
    fi
    
    BACKEND_STATE=$(echo "$STATUS" | jq -r '.BackendState // "Unknown"')
    TAILSCALE_IP=$(echo "$STATUS" | jq -r '.TailscaleIPs[0] // "N/A"')
    LOGGED_IN=$(echo "$STATUS" | jq -r '.Self.Online // false')
    
    if [ "$BACKEND_STATE" = "Running" ] && [ "$LOGGED_IN" = "true" ]; then
        echo "Connected ($TAILSCALE_IP)"
    elif [ "$BACKEND_STATE" = "Running" ]; then
        echo "Logged out"
    else
        echo "$BACKEND_STATE"
    fi
}

# Cobalto status (quick check)
get_cobalto_status() {
    COBALTO_HOST="cobalto.minerales.network"
    JELLYFIN_PORT="8096"
    
    # Quick connectivity check with short timeout
    RESULT=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://${COBALTO_HOST}:${JELLYFIN_PORT}/" 2>/dev/null)
    
    case "$RESULT" in
        200|204|301|302)
            echo "Online (Jellyfin OK)"
            ;;
        000)
            echo "Offline"
            ;;
        *)
            echo "Degraded ($RESULT)"
            ;;
    esac
}

# Syncthing status (quick check)
get_syncthing_status() {
    CONFIG="$HOME/.local/state/syncthing/config.xml"
    API_KEY=$(grep -oP '(?<=<apikey>)[^<]+' "$CONFIG" 2>/dev/null)
    
    if [ -z "$API_KEY" ]; then
        echo "No API key"
        return
    fi
    
    PING=$(curl -s -H "X-API-Key: $API_KEY" --connect-timeout 2 http://localhost:8384/rest/system/ping 2>/dev/null)
    
    if [ -z "$PING" ] || ! echo "$PING" | grep -q '"ping"'; then
        echo "Not running"
        return
    fi
    
    STATUS=$(curl -s -H "X-API-Key: $API_KEY" --connect-timeout 2 http://localhost:8384/rest/db/completion 2>/dev/null)
    NEED_BYTES=$(echo "$STATUS" | grep -oP '"needBytes":\s*\K[0-9]+' 2>/dev/null)
    
    if [ -z "$NEED_BYTES" ]; then
        echo "Error"
    elif [ "$NEED_BYTES" -gt 0 ]; then
        echo "Syncing"
    else
        echo "Synced"
    fi
}

# ============ System Resources ============

get_cpu_usage() {
    # Get CPU usage from /proc/stat (more reliable than top)
    read -r cpu user nice system idle rest < /proc/stat
    total1=$((user + nice + system + idle))
    idle1=$idle
    sleep 0.2
    read -r cpu user nice system idle rest < /proc/stat
    total2=$((user + nice + system + idle))
    idle2=$idle
    
    total_diff=$((total2 - total1))
    idle_diff=$((idle2 - idle1))
    
    if [ "$total_diff" -gt 0 ]; then
        usage=$(( (total_diff - idle_diff) * 100 / total_diff ))
        echo "${usage}%"
    else
        echo "N/A"
    fi
}

get_memory_usage() {
    # Parse /proc/meminfo
    MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    MEM_AVAIL=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    
    MEM_USED=$((MEM_TOTAL - MEM_AVAIL))
    MEM_TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $MEM_TOTAL/1024/1024}")
    MEM_USED_GB=$(awk "BEGIN {printf \"%.1f\", $MEM_USED/1024/1024}")
    MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
    
    echo "${MEM_USED_GB}G / ${MEM_TOTAL_GB}G (${MEM_PERCENT}%)"
}

get_disk_usage() {
    # Get root filesystem usage
    DISK_INFO=$(df -h / | tail -1)
    DISK_USED=$(echo "$DISK_INFO" | awk '{print $3}')
    DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
    DISK_PERCENT=$(echo "$DISK_INFO" | awk '{print $5}')
    
    echo "${DISK_USED} / ${DISK_TOTAL} (${DISK_PERCENT})"
}

# ============ Build Tooltip ============

TAILSCALE_STATUS=$(get_tailscale_status)
COBALTO_STATUS=$(get_cobalto_status)
SYNCTHING_STATUS=$(get_syncthing_status)

CPU_USAGE=$(get_cpu_usage)
MEM_USAGE=$(get_memory_usage)
DISK_USAGE=$(get_disk_usage)

TOOLTIP="Services:\\n"
TOOLTIP="${TOOLTIP}  Tailscale: ${TAILSCALE_STATUS}\\n"
TOOLTIP="${TOOLTIP}  Cobalto: ${COBALTO_STATUS}\\n"
TOOLTIP="${TOOLTIP}  Syncthing: ${SYNCTHING_STATUS}\\n"
TOOLTIP="${TOOLTIP}\\n"
TOOLTIP="${TOOLTIP}System:\\n"
TOOLTIP="${TOOLTIP}  CPU: ${CPU_USAGE}\\n"
TOOLTIP="${TOOLTIP}  Memory: ${MEM_USAGE}\\n"
TOOLTIP="${TOOLTIP}  Disk: ${DISK_USAGE}"

# Output JSON for waybar
# Using chevron-down (f078) as the visible toggle for the services/tray group
ICON=$(printf '\uf078')
echo "{\"text\":\"${ICON}\",\"tooltip\":\"${TOOLTIP}\",\"class\":\"normal\"}"
