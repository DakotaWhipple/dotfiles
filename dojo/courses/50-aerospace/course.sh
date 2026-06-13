# Course: aerospace — the tiling window manager. Live tasks verified
# through the aerospace CLI.
COURSE_TITLE="Aerospace: Window Mastery"
COURSE_DESC="Windows tile themselves; you just say where things go.
hjkl again — same language as vim and kitty, one level up.
These tasks are live: the dojo watches your actual windows."

LESSONS=(
  "focus:Focus and the alt layer"
  "workspaces:Workspaces — rooms for work"
  "layouts:Layouts, fullscreen, floating"
  "service:Service mode and rescue moves"
)

lesson_focus() {
  brief "Aerospace tiles every window — no overlapping, no dragging.
The alt key is the window layer:

  alt+h/j/k/l          FOCUS window left/down/up/right
  alt+shift+h/j/k/l    MOVE the focused window
  alt+enter            new kitty window, tiled in
  alt+n                capture a note (you know this one)

Same hjkl as vim motions and kitty panes. One grammar, three floors."

  # baseline so windows already in the workspace can't self-pass
  local awbase
  awbase=$(aerospace list-windows --workspace focused 2>/dev/null | wc -l | tr -d " "); awbase=${awbase:-1}

  watch_task "Open a second kitty window right here: alt+enter.
It will tile in next to this one." \
    '[ "$(aerospace list-windows --workspace focused 2>/dev/null | wc -l | tr -d " ")" -gt '"$awbase"' ]' \
    "alt+enter — aerospace tiles it automatically"

  guided "Bounce focus between the two windows: alt+h, alt+l.
Then grab one and MOVE it: alt+shift+h / alt+shift+l — watch
them swap places. Leave both open for the next lesson."

  quiz "Focus the window to the left?" "alt-h" ""
  quiz "MOVE the focused window right?" "alt-shift-l" ""
}

lesson_workspaces() {
  brief "Workspaces are numbered rooms. A window lives in exactly one;
you point your eyes at one at a time.

  alt+1..9          go to workspace N
  alt+shift+1..9    SEND the focused window to workspace N
  alt+tab           bounce between the last two workspaces

A working setup that sticks: 1 = terminal, 2 = browser,
3 = chat, 9 = parking lot. Muscle memory does the rest."

  watch_task "Take a field trip: alt+7. Look at the empty room.
The dojo passes the moment you arrive — come back with alt+tab." \
    '[ "$(aerospace list-workspaces --focused 2>/dev/null)" = "7" ]' \
    "alt+7 to go, alt+tab to bounce back"

  local w9base
  w9base=$(aerospace list-windows --workspace 9 2>/dev/null | grep -ci kitty); w9base=${w9base:-0}

  watch_task "Now move a WINDOW: focus your spare kitty window
(alt+h/l), send it to workspace 9 with alt+shift+9.
(It vanishes — it is waiting in room 9.)" \
    '[ "$(aerospace list-windows --workspace 9 2>/dev/null | grep -ci kitty)" -gt '"$w9base"' ]' \
    "focus the spare window, then alt+shift+9"

  guided "Go fetch it: alt+9, focus it, alt+shift+tab? No — send it
back with alt+shift+<this workspace number>, then alt+tab home.
(Or just leave it in 9 and close it there with cmd+w.)"

  quiz "Send the focused window to workspace 4?" "alt-shift-4" ""
  quiz "Bounce between the last two workspaces?" "alt-tab" ""
}

lesson_layouts() {
  brief "How the tiles arrange themselves:

  alt+/            toggle tiles split direction (h/v)
  alt+,            ACCORDION — windows stack with a peek;
                   focus cycles through them (great on a laptop)
  alt+f            fullscreen the focused window
  alt+shift+f      float / unfloat (escape the tiling)
  alt+minus/equal  shrink / grow the focused window"

  guided "With at least two windows on this workspace: alt+, for
accordion (alt+h/l cycles), alt+/ back to tiles. Then alt+f
fullscreen on/off. Try alt+minus and alt+equal to resize."

  quiz "Accordion layout?" "alt-,|alt-comma" ""
  quiz "Fullscreen toggle?" "alt-f" ""
  quiz "Float a stubborn window out of the tiling?" "alt-shift-f" ""
}

lesson_service() {
  brief "alt+shift+; enters SERVICE mode — the rescue layer:

  esc          reload aerospace config (and back to normal)
  r            FLATTEN the layout tree — fixes weird nesting
  f            float/unfloat
  backspace    close every window here EXCEPT the focused one
  alt+shift+hjkl   JOIN this window with its neighbor (makes
                   them share a column/row), then back to normal

When a workspace gets tangled: alt+shift+; then r. Layout therapy."

  guided "Try it safely: alt+shift+; then r. The layout flattens
and you are back in normal mode. (esc in service mode also
reloads the config — useful after editing aerospace.toml.)"

  quiz "Enter service mode?" "alt-shift-;|alt-shift-semicolon" ""
  quiz "Fix a tangled layout (in service mode)?" "r" "flatten-workspace-tree"
  quiz "Close everything except this window (service mode)?" "backspace" ""

  brief "That is the whole window layer. Notice the design:
  vim:    hjkl moves the cursor      (text)
  kitty:  ctrl+hjkl moves focus      (panes)
  aero:   alt+hjkl moves focus       (windows)
Modifier = floor. Keys never change. That is the rice's thesis."
}

drills() {
  add_quiz "Focus window left?" "alt-h"
  add_quiz "Move window down?" "alt-shift-j"
  add_quiz "Go to workspace 3?" "alt-3"
  add_quiz "Send window to workspace 5?" "alt-shift-5"
  add_quiz "Bounce to previous workspace?" "alt-tab"
  add_quiz "New kitty window?" "alt-enter"
  add_quiz "Accordion layout?" "alt-,|alt-comma"
  add_quiz "Fullscreen?" "alt-f"
  add_quiz "Float toggle?" "alt-shift-f"
  add_quiz "Service mode?" "alt-shift-;|alt-shift-semicolon"
  add_quiz "Flatten a broken layout (service mode)?" "r"
  add_quiz "Capture a note from anywhere?" "alt-n"
  add_quiz "Grow the focused window?" "alt-=|alt-equal"
}
