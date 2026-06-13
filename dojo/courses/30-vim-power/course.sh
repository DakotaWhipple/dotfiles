# Course: vim power — LazyVim, the plugins, and your specific setup.
COURSE_TITLE="Vim: LazyVim Superpowers"
COURSE_DESC="Your nvim is LazyVim plus a curated set: flash, harpoon,
zk-nvim, smart-splits. This course is the layer ABOVE the vim language —
finding things, jumping, LSP, and living in a project."

LESSONS=(
  "leader:Space — the leader key"
  "flash:Flash — teleport anywhere"
  "extras:Comments, pairs, completion"
  "lsp:LSP — the editor that understands code"
  "harpoon:Harpoon and buffers"
  "workflow:Explorer, git, sessions"
)

lesson_leader() {
  brief "Press space in NORMAL mode and WAIT: which-key pops up a
menu of everything. You never have to memorize — space is a
discoverable menu tree. The big ones:

  space space    find files (smart)      space ff   find files
  space /        grep the whole project
  space ,        switch between open buffers
  space sk       search KEYMAPS — ask the editor itself!
  space sh       search help

Searching keymaps (space sk) is how you answer your own
'what was that key?' questions forever."

  guided "Open nvim in ~/dotfiles (cd ~/dotfiles && nvim).
Press space, just look at the which-key menu. Esc.
Then space ff, type 'kitty', enter — you are in kitty.conf."

  guided "Still in nvim: space /, search for: note-capture
Every match across the repo. Enter jumps to one. Quit when done."

  quiz "Grep across the whole project?" "space /|leader /|space sg" ""
  quiz "Search all keymaps from inside nvim?" "space sk|leadersk|spacesk" \
    "which-key + space sk means nvim documents itself"
}

lesson_flash() {
  brief "flash.nvim: press s plus the first TWO characters of where
you want to go — labels appear on every match — press the label
letter and you are THERE. Anywhere on screen, ~4 keystrokes.

  s + two chars + label     jump anywhere
  S                          select syntax nodes (expanding)

It replaces 'jjjjjjwwww'. The drills below are far away on
purpose — try s, it should feel like cheating."

  vim_drill "flash strike" \
"Change the word 'wrong' (far down) to 'right'.
Try: s wr, label, then ciw. (scrolling there also works,
but the timer knows.)" \
    $'line 01\nline 02\nline 03\nline 04\nline 05\nline 06\nline 07\nline 08\nline 09\nline 10\nline 11\nline 12\nthis one is wrong here\nline 14\nline 15' \
    $'line 01\nline 02\nline 03\nline 04\nline 05\nline 06\nline 07\nline 08\nline 09\nline 10\nline 11\nline 12\nthis one is right here\nline 14\nline 15'

  vim_drill "flash and burn" \
"Delete the line containing 'ZAP'. s + za + label, then dd." \
    $'data 1\ndata 2\ndata 3\ndata 4\ndata 5\ndata 6\ndata 7\nZAP goes this one\ndata 9\ndata 10\ndata 11' \
    $'data 1\ndata 2\ndata 3\ndata 4\ndata 5\ndata 6\ndata 7\ndata 9\ndata 10\ndata 11'

  quiz "Flash-jump key?" "s" \
    "in operator mode too: ds<chars> deletes up to a flash target"
}

lesson_extras() {
  brief "Quality-of-life that is always on:

  gcc          comment/uncomment this line
  gc + motion  comment a range (gcip = comment a paragraph;
               select lines with V first, then gc)
  mini.pairs   types the closing ) ] \" for you
  completion   menu appears as you type (blink.cmp) — keep
               typing to filter, enter to accept, ctrl-e to dismiss
  s n a c k s  notifications, dashboards — already themed"

  vim_drill "comment out" \
"Comment out BOTH print lines in this lua file. gcc on each,
or Vj then gc. (It is .lua so vim knows the comment style.)" \
    $'print("debug a")\nprint("debug b")\nreturn 42' \
    $'-- print("debug a")\n-- print("debug b")\nreturn 42' \
    "drill.lua"

  quiz "Comment/uncomment the current line?" "gcc" ""
  quiz "Comment a visual selection?" "gc" ""
}

lesson_lsp() {
  brief "LSP = a language server reads your code and tells nvim what
it MEANS. Servers auto-install (mason). The keys:

  gd           go to definition       gr   list references
  K            hover docs for the symbol under cursor
  space cr     RENAME symbol — everywhere, correctly
  space ca     code actions (auto-fixes, imports)
  ]d / [d      next / previous diagnostic (error/warning)

This is the IntelliJ stuff, in the terminal."

  vim_drill "the big rename" \
"Rename the variable cnt to count EVERYWHERE (4 places).
Best: cursor on any cnt, space cr, type count, enter.
(:%s/cnt/count/g also works — but try the LSP way.)" \
    $'local cnt = 0\nfor i = 1, 10 do\n  cnt = cnt + i\nend\nprint(cnt)\nreturn cnt' \
    $'local count = 0\nfor i = 1, 10 do\n  count = count + i\nend\nprint(count)\nreturn count' \
    "drill.lua"

  guided "Open any lua file from your config (space ff in ~/.config/nvim).
Put the cursor on a function name. K for docs. gd to jump into a
definition, ctrl-o to jump back."

  quiz "Rename a symbol project-wide?" "space cr|leadercr|spacecr" ""
  quiz "Hover docs for the thing under the cursor?" "shift-k|k" ""
  quiz "Jump to definition / and back?" "gd ctrl-o|gd and ctrl-o|gd, ctrl-o" \
    "ctrl-o walks back through your jump history, ctrl-i forward"
}

lesson_harpoon() {
  brief "You work in 2-5 files at a time. Harpoon pins them:

  space H      harpoon (pin) the current file
  space h      the harpoon menu (edit/reorder your pins)
  space 1..5   JUMP straight to pin 1-5

Plus plain buffers: space , fuzzy-picks open buffers,
shift-h / shift-l cycle through the bufferline tabs,
space bd closes a buffer."

  guided "In nvim, open two different files (space ff). On each:
space H to pin it. Then space 1 and space 2 — instant switching.
space h shows the list."

  quiz "Pin the current file to harpoon?" "space h|space shift-h|leaderh" ""
  quiz "Jump to your 2nd harpooned file?" "space 2|leader2|space-2" ""
  quiz "Cycle to the next buffer?" "shift-l|l" ""
}

lesson_workflow() {
  brief "The rest of living in a project:

  space e      file explorer (neo-tree). In the tree:
               a = add file, d = delete, r = rename, ? = help
  space gg     lazygit if installed (you use jj — still handy
               for browsing diffs and history)
  ]h / [h      jump between changed hunks   space ghs  stage hunk
  space qq     quit — session restores next time (persistence.nvim)
  ctrl-hjkl    move between SPLITS — and out into kitty panes
               seamlessly (smart-splits). Same keys, no seam."

  guided "In nvim in ~/dotfiles: space e to open the tree. Move with
j/k, expand with enter, press ? to see the tree's own keys. Make a
split (:vsplit), then ctrl-h / ctrl-l between them. q closes the tree."

  quiz "Toggle the file explorer?" "space e|leadere|spacee" ""
  quiz "Move to the split on the left (works into kitty too)?" "ctrl-h" ""
  quiz "Add a new file from inside the explorer tree?" "a" ""
}

drills() {
  add_quiz "Find files?" "space ff|space space|leaderff"
  add_quiz "Grep the project?" "space /|space sg"
  add_quiz "Search keymaps?" "space sk"
  add_quiz "Flash-jump anywhere?" "s"
  add_quiz "Comment the current line?" "gcc"
  add_quiz "Rename a symbol everywhere?" "space cr"
  add_quiz "Go to definition?" "gd"
  add_quiz "Jump back after gd?" "ctrl-o"
  add_quiz "Hover docs?" "shift-k|k"
  add_quiz "Pin file to harpoon?" "space h|space shift-h"
  add_quiz "Jump to harpoon pin 1?" "space 1"
  add_quiz "Toggle file explorer?" "space e"
  add_quiz "Next changed git hunk?" "]h"
  add_quiz "Switch among open buffers (picker)?" "space ,|space comma"

  add_vim "speed: flash strike" \
    "Change 'cold' (far below) to 'hot' — s co, label, ciw." \
    $'x 1\nx 2\nx 3\nx 4\nx 5\nx 6\nx 7\nx 8\nx 9\nx 10\nthe soup is cold today\nx 12' \
    $'x 1\nx 2\nx 3\nx 4\nx 5\nx 6\nx 7\nx 8\nx 9\nx 10\nthe soup is hot today\nx 12'
  add_vim "speed: comment two lines" \
    "Comment out both log lines (Vj gc, or gcc j .)." \
    $'log("a")\nlog("b")\ndone()' \
    $'-- log("a")\n-- log("b")\ndone()' \
    "gym.lua"
}
