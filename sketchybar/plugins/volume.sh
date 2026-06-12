#!/usr/bin/env bash
source "$HOME/.config/theme/colors.sh"

vol="${INFO:-$(osascript -e 'output volume of (get volume settings)')}"
if [ "$vol" -eq 0 ] 2>/dev/null; then icon="󰖁"
elif [ "$vol" -lt 34 ]; then icon="󰕿"
elif [ "$vol" -lt 67 ]; then icon="󰖀"
else icon="󰕾"
fi

sketchybar --set "$NAME" icon="$icon" icon.color="0xff$ACCENT" label="${vol}%"
