#!/bin/sh

CONFIG="$HOME/.local/state/syncthing/config.xml"

# Get API key from config.xml
API_KEY=$(grep -oP '(?<=<apikey>)[^<]+' "$CONFIG" 2>/dev/null)

if [ -z "$API_KEY" ]; then
    echo '{"text":"","tooltip":"Syncthing: No API key","class":"error"}'
    exit 0
fi

# Check if syncthing is running
PING=$(curl -s -H "X-API-Key: $API_KEY" http://localhost:8384/rest/system/ping 2>/dev/null)

if [ -z "$PING" ] || ! echo "$PING" | grep -q '"ping"'; then
    echo '{"text":"","tooltip":"Syncthing: Not running","class":"error"}'
    exit 0
fi

# Get overall completion status
STATUS=$(curl -s -H "X-API-Key: $API_KEY" http://localhost:8384/rest/db/completion 2>/dev/null)
NEED_BYTES=$(echo "$STATUS" | grep -oP '"needBytes":\s*\K[0-9]+' 2>/dev/null)

if [ -z "$NEED_BYTES" ]; then
    echo '{"text":"","tooltip":"Syncthing: Error","class":"error"}'
    exit 0
fi

if [ "$NEED_BYTES" -gt 0 ]; then
    echo "{\"text\":\"\",\"tooltip\":\"Syncthing: Syncing (${NEED_BYTES} bytes)\",\"class\":\"syncing\"}"
else
    echo '{"text":"","tooltip":"Syncthing: Up to date","class":"ok"}'
fi
