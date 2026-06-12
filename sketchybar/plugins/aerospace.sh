#!/usr/bin/env bash
# Workspace pill: highlighted when focused, visible when occupied, hidden otherwise.
source "$HOME/.config/theme/colors.sh"
sid="$1"
FOCUSED_WORKSPACE="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"

if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set "$NAME" drawing=on \
    background.drawing=on label.color="0xff$BG_DARK"
elif [ "$(aerospace list-windows --workspace "$sid" --count 2>/dev/null)" -gt 0 ] 2>/dev/null; then
  sketchybar --set "$NAME" drawing=on \
    background.drawing=off label.color="0xff$FG_MUTED"
else
  sketchybar --set "$NAME" drawing=off
fi
