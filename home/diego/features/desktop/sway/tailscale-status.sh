#!/bin/sh
# Waybar module: Tailscale connection status

# Network-wired icon (f6ff)
ICON=$(printf '\uf6ff')

# Check if tailscale CLI is available
if ! command -v tailscale >/dev/null 2>&1; then
    echo "{\"text\":\"${ICON}\",\"tooltip\":\"Tailscale: Not installed\",\"class\":\"error\"}"
    exit 0
fi

# Get tailscale status as JSON
STATUS=$(tailscale status --json 2>/dev/null)

if [ -z "$STATUS" ]; then
    echo "{\"text\":\"${ICON}\",\"tooltip\":\"Tailscale: Daemon not running\",\"class\":\"error\"}"
    exit 0
fi

# Parse the status using jq
BACKEND_STATE=$(echo "$STATUS" | jq -r '.BackendState // "Unknown"')
TAILSCALE_IP=$(echo "$STATUS" | jq -r '.TailscaleIPs[0] // "N/A"')
LOGGED_IN=$(echo "$STATUS" | jq -r '.Self.Online // false')

case "$BACKEND_STATE" in
    "Running")
        if [ "$LOGGED_IN" = "true" ]; then
            echo "{\"text\":\"${ICON}\",\"tooltip\":\"Tailscale: Connected\\nIP: ${TAILSCALE_IP}\",\"class\":\"connected\"}"
        else
            echo "{\"text\":\"${ICON}\",\"tooltip\":\"Tailscale: Logged out\",\"class\":\"disconnected\"}"
        fi
        ;;
    "Stopped"|"NoState")
        echo "{\"text\":\"${ICON}\",\"tooltip\":\"Tailscale: Stopped\",\"class\":\"disconnected\"}"
        ;;
    "NeedsLogin"|"NeedsMachineAuth")
        echo "{\"text\":\"${ICON}\",\"tooltip\":\"Tailscale: Needs authentication\",\"class\":\"disconnected\"}"
        ;;
    *)
        echo "{\"text\":\"${ICON}\",\"tooltip\":\"Tailscale: ${BACKEND_STATE}\",\"class\":\"error\"}"
        ;;
esac
