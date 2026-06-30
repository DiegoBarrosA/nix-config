#!/bin/sh
# Waybar module: date+time display with calendar and world clocks in tooltip

local_time=$(date '+%a %b %d  %H:%M')

cali=$(TZ='America/Los_Angeles' date '+%H:%M')
india=$(TZ='Asia/Kolkata' date '+%H:%M')
canada=$(TZ='America/Toronto' date '+%H:%M')
madrid=$(TZ='Europe/Madrid' date '+%H:%M')
uk=$(TZ='Europe/London' date '+%H:%M')

jq -cn \
  --arg text "$local_time" \
  --arg cali "$cali" \
  --arg india "$india" \
  --arg canada "$canada" \
  --arg madrid "$madrid" \
  --arg uk "$uk" \
  --arg calendar "$(cal)" \
  '{text: $text, tooltip: "<tt><small>\($calendar)</small></tt>\n───────────────────────\n<tt>California  \($cali)\nIndia       \($india)\nCanada      \($canada)\nMadrid      \($madrid)\nUK          \($uk)</tt>"}'
