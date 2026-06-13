# Course: kitty — tabs, splits, modes. Uses kitty remote control to
# WATCH you do things (allow_remote_control socket-only in kitty.conf).
COURSE_TITLE="Kitty: Tabs, Splits, Modes"
COURSE_DESC="You live in tabs — time to own splits too. These tasks are
live: the dojo watches your actual kitty layout and passes when it sees
the real thing. (Run this inside kitty.)"

LESSONS=(
  "tabs:Tabs and the manage mode"
  "splits:Splits, finally"
  "navigate:Moving and resizing"
  "stack:Stack — the zoom trick"
  "extras:Scrollback, hints, oddments"
)

lesson_tabs() {
  brief "Tabs you know — here is the full kit:

  cmd+t        new tab (keeps current directory)
  ctrl+;       MANAGE MODE — a vim-style mode for the terminal:
     h / l        previous / next tab
     shift+h/l    move this tab left / right
     1..5         jump to tab N
     ,            retitle this tab
     n            new tab     esc/enter    leave the mode

One mode key, then single letters. Just like vim."

  # baseline so pre-existing tabs can't self-pass the task
  local tbase; tbase=$(kitty_tab_count); tbase=${tbase:-1}

  watch_task "Open a new tab with cmd+t, then come back to this one
(ctrl+; then h, or cmd+shift+[)." \
    '[ "$(kitty_tab_count)" -gt '"$tbase"' ] 2>/dev/null' \
    "cmd+t makes the tab; ctrl+; h walks back"

  watch_task "Give THIS tab a title: ctrl+; then , (comma) —
type exactly:  sensei   and press enter." \
    '[ "$(kitty_tab_title)" = "sensei" ] 2>/dev/null' \
    "ctrl+; , then type sensei"

  quiz "Enter kitty manage mode?" "ctrl-;|ctrl-semicolon" ""
  quiz "Jump straight to tab 3?" "ctrl-; 3|3" \
    "ctrl+; then the number — h/l for stepping"
}

lesson_splits() {
  brief "A split is just two shells side by side — editor in one,
tests or logs in the other, no tab flipping.

  cmd+d          split VERTICALLY (new pane to the right)
  cmd+shift+d    split HORIZONTALLY (new pane below)
  cmd+enter      split along whichever side is longer
  close one:     type exit (or ctrl+d) in it — or ctrl+; x

The dojo is watching your window count. Go."

  # baseline so pre-existing panes can't self-pass the tasks
  local wbase; wbase=$(kitty_win_count); wbase=${wbase:-1}

  watch_task "Split this window vertically: cmd+d" \
    '[ "$(kitty_win_count)" -gt '"$wbase"' ] 2>/dev/null' \
    "cmd+d — a new pane appears on the right"

  watch_task "Now close the new pane: hop into it (ctrl+l),
then type exit (or press ctrl+d on an empty prompt)." \
    '[ "$(kitty_win_count)" = '"$wbase"' ] 2>/dev/null' \
    "ctrl+l to focus it, then exit"

  rm -f "$SANDBOX/.split2"
  watch_task "One more: horizontal this time, cmd+shift+d —
then close it again (ctrl+j to reach it, exit)." \
    '[ "$(kitty_win_count)" -gt '"$wbase"' ] && touch "$SANDBOX/.split2"; [ -f "$SANDBOX/.split2" ] && [ "$(kitty_win_count)" = '"$wbase"' ]' \
    "cmd+shift+d, then exit inside it" 240

  quiz "Vertical split / horizontal split?" "cmd-d cmd-shift-d|cmd-d and cmd-shift-d|cmd-d, cmd-shift-d" ""
}

lesson_navigate() {
  brief "Moving between panes — the same keys as everything else:

  ctrl+h/j/k/l       focus pane left/down/up/right
                     (inside nvim, the SAME keys cross between
                     nvim splits and kitty panes — smart-splits)
  ctrl+; j/k         cycle panes from manage mode
  ctrl+alt+hjkl      resize on the fly
  ctrl+shift+r       resize MODE (hjkl to resize, = resets, esc)"

  local wbase; wbase=$(kitty_win_count); wbase=${wbase:-1}
  rm -f "$SANDBOX/.nav"
  watch_task "Make a split (cmd+d). Bounce between the panes a few
times with ctrl+h and ctrl+l — feel it — then close the extra
pane (exit) to finish." \
    '[ "$(kitty_win_count)" -gt '"$wbase"' ] && touch "$SANDBOX/.nav"; [ -f "$SANDBOX/.nav" ] && [ "$(kitty_win_count)" = '"$wbase"' ]' \
    "cmd+d, ctrl+h / ctrl+l to hop, exit in the extra pane" 240

  quiz "Focus the pane to the left?" "ctrl-h" ""
  quiz "Enter resize mode?" "ctrl-shift-r" "hjkl resizes, = resets, esc leaves"
}

lesson_stack() {
  brief "The trick that makes splits livable: STACK layout.
One pane goes (visually) fullscreen; the others wait behind it.

  cmd+shift+z    toggle stack  <->  splits   (also: ctrl+; z)

Split workflow: code left, logs right — need to read a long
stack trace? cmd+shift+z zooms the pane. Done? cmd+shift+z back."

  local wbase; wbase=$(kitty_win_count); wbase=${wbase:-1}

  watch_task "Make sure you have a split (cmd+d), then zoom:
cmd+shift+z. The dojo is watching the layout." \
    '[ "$(kitty_tab_layout)" = "stack" ] && [ "$(kitty_win_count)" -gt '"$wbase"' ]' \
    "cmd+d first if needed, then cmd+shift+z"

  watch_task "Toggle back out of stack (cmd+shift+z again), then
clean up the extra pane (exit)." \
    '[ "$(kitty_tab_layout)" != "stack" ] && [ "$(kitty_win_count)" = '"$wbase"' ]' \
    "cmd+shift+z, then exit in the spare pane"

  quiz "Zoom/unzoom a pane (stack toggle)?" "cmd-shift-z" ""
}

lesson_extras() {
  brief "Loose ends worth knowing (kitty_mod = ctrl+shift):

  ctrl+shift+h     browse SCROLLBACK in a pager — and because
                   your pager opens it, you can search with /
  ctrl+shift+e     URL hints — every link on screen gets a
                   letter, press it to open
  cmd+plus/minus   font size up / down
  kitten themes    theme browser (you have your own vibes, but)
  kitty +kitten icat IMG    images in the terminal

And: kitty.conf is at ~/dotfiles/kitty/kitty.conf — every key
in this course is defined there, greppable, changeable."

  guided "Press ctrl+shift+e right now — this screen has no URLs?
Then run: echo https://sw.kovidgoyal.net/kitty/ and try again.
A letter appears over the link; pressing it opens the browser."

  guided "Press ctrl+shift+h to open this lesson in the scrollback
pager. Search for the word 'stack' with /stack. q to quit."

  quiz "See scrollback in a pager?" "ctrl-shift-h" ""
  quiz "Open a URL on screen with hints?" "ctrl-shift-e" ""
}

drills() {
  add_quiz "New tab?" "cmd-t"
  add_quiz "Kitty manage mode?" "ctrl-;|ctrl-semicolon"
  add_quiz "Vertical split?" "cmd-d"
  add_quiz "Horizontal split?" "cmd-shift-d"
  add_quiz "Focus pane to the right?" "ctrl-l"
  add_quiz "Zoom a pane (stack toggle)?" "cmd-shift-z"
  add_quiz "Resize mode?" "ctrl-shift-r"
  add_quiz "Close a pane from manage mode?" "x"
  add_quiz "Retitle a tab from manage mode?" ",|comma"
  add_quiz "Scrollback pager?" "ctrl-shift-h"
  add_quiz "URL hints?" "ctrl-shift-e"
  add_quiz "Move this tab to the right (manage mode)?" "shift-l"
}
