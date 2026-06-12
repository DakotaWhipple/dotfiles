#!/usr/bin/env bash
# notes — journal status + open tasks across the vault. Click to jot.
source "$HOME/.config/theme/colors.sh"
NOTES="${ZK_NOTEBOOK_DIR:-$HOME/notes}"

tasks=$(grep -rh -- '- \[ \]' "$NOTES" 2>/dev/null | wc -l | tr -d ' ')
if [ -f "$NOTES/journal/$(date +%Y-%m-%d).md" ]; then
  color="0xff$ACCENT"   # journal touched today
else
  color="0xff$FG_MUTED" # nothing jotted yet
fi

sketchybar --set "$NAME" icon=󰠮 icon.color="$color" label="$tasks"
