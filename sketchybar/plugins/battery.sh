#!/usr/bin/env bash
source "$HOME/.config/theme/colors.sh"

pct="$(pmset -g batt | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
charging="$(pmset -g batt | grep -c 'AC Power')"
[ -n "$pct" ] || { sketchybar --set "$NAME" drawing=off; exit 0; }

color="0xff$GREEN"
if [ "$charging" -gt 0 ]; then
  icon="󰂄"
elif [ "$pct" -gt 80 ]; then icon="󰁹"
elif [ "$pct" -gt 60 ]; then icon="󰂀"
elif [ "$pct" -gt 40 ]; then icon="󰁾"
elif [ "$pct" -gt 20 ]; then icon="󰁻"; color="0xff$YELLOW"
else icon="󰁺"; color="0xff$RED"
fi

sketchybar --set "$NAME" icon="$icon" icon.color="$color" label="${pct}%"
