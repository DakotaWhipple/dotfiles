#!/bin/sh
# Keybind hint bar for kitty's manage/resize modes.
#
# Drawn as a kitty *dock* (launch --dock-type=os-window-bottom-edge): a
# fixed-size, non-focusable window pinned to the bottom edge that automatically
# follows the active tab, so the one bar window persists across tab switches —
# matching the keyboard mode, which is itself per-OS-window. Unlike the old
# approach of splitting in a real window it does NOT consume a slot in the
# layout, and unlike the desktop panel it used to be it lives inside kitty
# itself (so it tracks the window, theme and font, and needs no separate
# socket). The dock is created directly by the `launch` action in kitty.conf;
# this script only provides the rendered content, the live mode highlight and
# the teardown:
#
#   mode-bar.sh render          (internal) what runs *inside* the dock window;
#                               draws the active mode's row and repaints on changes
#   mode-bar.sh signal <mode>   tell the running dock which mode is now active
#                               (manage|resize) so it swaps to that mode's hints
#   mode-bar.sh close           tear the dock down (matches the --var MODEBAR=1 tag)
#
# The highlight is updated in place rather than by recreating the dock: the
# render process blocks on `read`, and `signal` injects a mode token onto its
# stdin via `kitty @ send-text`, which triggers a repaint. This avoids the
# flicker and layout churn of closing/reopening the dock on every mode switch.
#
# Kept as a script to avoid nested quoting inside the kitty map actions.

# kitty's per-instance remote-control socket, inherited from the parent kitty
# (kitty appends the pid, e.g. /tmp/kitty-11814, so we cannot hardcode it).
SOCK=${KITTY_LISTEN_ON:-unix:/tmp/kitty}
KITTY=/Applications/kitty.app/Contents/MacOS/kitty
[ -x "$KITTY" ] || KITTY=$(command -v kitty)

e=$(printf '\033')
MAN_HINTS='h/l tab · j/k win · t detach · n new · s/v split · z zoom · x close · , name · r resize · esc exit'
RES_HINTS='h/j/k/l shrink·grow · = reset · esc back'

# Repaint the single-row bar for the active mode: only that mode's hints are
# shown (bright magenta label + default-fg hints). Clears first so the previous
# mode's text is gone, homes the cursor, and emits no trailing newline so the
# 1-row screen never scrolls. Line-wrap stays disabled so an over-long line
# truncates at the right edge instead of wrapping onto (and scrolling) a row
# that does not exist.
draw() {  # $1=manage|resize
    if [ "$1" = resize ]; then label=RESIZE; hints=$RES_HINTS; else label=MANAGE; hints=$MAN_HINTS; fi
    printf '%s[2J%s[H  %s[1;35m◆ %s%s[0m  %s' "$e" "$e" "$e" "$label" "$e" "$hints"
}

case "${1:-render}" in
  close)
    "$KITTY" @ --to "$SOCK" close-window --match var:MODEBAR=1 2>/dev/null
    ;;
  signal)
    # Push the new active mode onto the render process's stdin.
    printf '%s\n' "${2:-manage}" | "$KITTY" @ --to "$SOCK" send-text --match var:MODEBAR=1 --stdin 2>/dev/null
    ;;
  render | *)
    stty -echo 2>/dev/null    # the injected mode tokens must not echo onto the bar
    printf '%s[?25l%s[?7l' "$e" "$e"   # hide cursor, disable line-wrap
    draw manage
    # Block on stdin; each token from `signal` repaints. Exits (and so closes
    # the dock) when stdin hits EOF, i.e. when the window is torn down.
    while IFS= read -r line; do
      case "$line" in
        manage | resize) draw "$line" ;;
      esac
    done
    ;;
esac
