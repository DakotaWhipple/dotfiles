# Course: vim core — the editing language itself. Real nvim, timed drills.
COURSE_TITLE="Vim: The Language"
COURSE_DESC="Vim is a language: verbs (delete, change, yank) applied to
nouns (words, lines, paragraphs). Every drill opens real nvim and is
timed — come back and beat your times."

LESSONS=(
  "survival:Survival — modes, save, quit, undo"
  "moving:Moving without the mouse"
  "verbs:The grammar — verbs and motions"
  "precision:Precision strikes (f, /, *, %)"
  "power:Counts, repeats, visual mode"
  "objects:Text objects — the killer feature"
)

lesson_survival() {
  brief "Vim has modes. You are usually in NORMAL mode, where keys
are commands, not text. The essentials:

  i            INSERT mode (type text)   — a inserts AFTER cursor
  esc          back to NORMAL mode
  A            jump to end of line and insert (capital a)
  :w           save     :q  quit     :wq  save and quit
  :q!          quit and THROW AWAY changes
  u            undo     ctrl-r  redo

When in doubt: mash esc, then u."

  vim_drill "first edit" \
"The file says 'hello'. Make it say 'hello world', save, quit.
(A jumps to end-of-line in insert mode; esc, then :wq)" \
    "hello" \
    "hello world"

  vim_drill "line deleter" \
"One line does not belong. In NORMAL mode, dd deletes a whole line.
Put the cursor on it (j/k to move down/up), dd, then :wq." \
    $'milk\neggs\nDELETE ME\nbread' \
    $'milk\neggs\nbread'

  quiz "Quit without saving your mess?" ":q!" ""
  quiz "Undo?" "u" "ctrl-r redoes; vim keeps deep undo history"
}

lesson_moving() {
  brief "Stay out of insert mode — NORMAL mode is home. Moving:

  h j k l      left, down, up, right (you know this from aerospace!)
  w / b        next word / back a word        e   end of word
  0 / \$        start of line / end of line
  gg / G       top of file / bottom of file
  { / }        previous / next paragraph
  ctrl-d/u     half-page down/up (yours auto-centers with zz)
  42G          jump straight to line 42"

  vim_drill "bottom feeder" \
"Delete the LAST line of this file. From anywhere: G, then dd.
Two keys to cross the whole file." \
    $'keep 1\nkeep 2\nkeep 3\nkeep 4\nkeep 5\nkeep 6\nkeep 7\nkeep 8\nDELETE ME' \
    $'keep 1\nkeep 2\nkeep 3\nkeep 4\nkeep 5\nkeep 6\nkeep 7\nkeep 8'

  vim_drill "line sniper" \
"Delete the first word of line 5 (the word 'BAD').
Try: 5G to jump to line 5, 0 for line start, dw to delete a word." \
    $'one fine line\ntwo fine lines\nthree fine lines\nfour fine lines\nBAD five fine lines\nsix fine lines' \
    $'one fine line\ntwo fine lines\nthree fine lines\nfour fine lines\nfive fine lines\nsix fine lines' \
    "drill.txt"

  quiz "Jump to the top of the file?" "gg" ""
  quiz "Jump to end of the current line?" "\$|dollar" ""
}

lesson_verbs() {
  brief "The grammar. verb + motion = edit:

  d = delete    c = change (delete + insert)    y = yank (copy)

  dw   delete to next word        d\$   delete to end of line
  cw   change a word              dd/yy/cc   whole line
  p    put (paste) after          P    put before

This composes: anything that moves can be deleted, changed,
or yanked. Learn one new motion, get three new edits free."

  vim_drill "word swap" \
"Make 'brown' say 'red'. Cursor onto brown (w w hops words),
then cw, type red, esc, :wq." \
    "the quick brown fox" \
    "the quick red fox"

  vim_drill "duplicator" \
"Duplicate the only line so it appears twice. yy copies the line,
p pastes it below. Three keys total." \
    "make it double" \
    $'make it double\nmake it double'

  vim_drill "line mover" \
"Move the FIRST line to the BOTTOM. dd cuts it, G jumps to the
end, p pastes after. (dd G p)" \
    $'move me down\nalpha\nbeta\ngamma' \
    $'alpha\nbeta\ngamma\nmove me down'

  quiz "Change a word (delete it and enter insert)?" "cw|ciw" ""
  quiz "Yank (copy) the current line?" "yy" ""
}

lesson_precision() {
  brief "Stop holding l. Jump exactly where you mean:

  fx     jump ONTO next 'x' on this line    tx   stop just before
  ;      repeat the last f/t    ,   repeat it backwards
  /word  search down (n = next match, N = previous)
  *      search the word already under your cursor
  %      bounce between matching ( ) [ ] { }

These also feed the grammar: df) deletes up to AND including
the next ')'. ct: changes everything up to the next ':'."

  vim_drill "quote surgeon" \
"Change the text inside the quotes to: cat
ci\" from anywhere on the line — change inside quotes." \
    'animal = "wombat"' \
    'animal = "cat"'

  vim_drill "argument fixer" \
"Make the call read greet(world). ci( changes everything inside
the parentheses — cursor can be anywhere on the line." \
    "greet(plnaet earht)" \
    "greet(world)"

  vim_drill "error hunter" \
"One line contains ERROR. Find it with /ERROR enter, delete the
whole line with dd. (n would jump to later matches.)" \
    $'status ok\nstatus ok\nstatus ok\nstatus ERROR bad\nstatus ok\nstatus ok\nstatus ok\nstatus ok' \
    $'status ok\nstatus ok\nstatus ok\nstatus ok\nstatus ok\nstatus ok\nstatus ok'

  quiz "Search for the word already under the cursor?" "*" ""
  quiz "Jump onto the next 'x' on this line?" "fx" \
    "; repeats it, , reverses — f and t are tiny but constant wins"
}

lesson_power() {
  brief "Multipliers:

  3dd        delete 3 lines      2w   two words forward
  .          REPEAT the last change — the most underrated key
  V          select whole lines   ctrl-v   select a column/block
  J          join the next line onto this one
  > / <      indent / dedent (in visual: select then >)
  gUiw       UPPERCASE a word (gu lowercases)"

  vim_drill "triple kill" \
"Delete the three BAD lines in one command: cursor on the first
BAD, then 3dd." \
    $'good morning\nBAD one\nBAD two\nBAD three\ngood night' \
    $'good morning\ngood night'

  vim_drill "joiner" \
"Make these three lines one line: 'one two three'.
J joins the next line up with a space. Or count it: 3J? Try!" \
    $'one\ntwo\nthree' \
    "one two three"

  vim_drill "dot machine" \
"Every line ends with ' TODO'. Remove all three TODOs.
Elegant way: on the first, \$ then daw — then j and . (dot)
repeats the whole edit on each next line." \
    $'wash dishes TODO\nfeed cat TODO\nlearn vim TODO' \
    $'wash dishes\nfeed cat\nlearn vim'

  quiz "Repeat the last change?" "." \
    "pairs with n: /find a pattern, fix once, then n.n.n. across the file"
  quiz "Block (column) visual mode?" "ctrl-v" ""
}

lesson_objects() {
  brief "Text objects: instead of 'from here to there', name the
THING. i = inside, a = around (includes delimiters):

  iw / aw      word            ip / ap     paragraph
  i\" / a\"      quoted string   i( / a(     parentheses
  i{ / a{      braces          it / at     html/xml tag

ci\" works with your cursor ANYWHERE on the line — vim finds the
quotes. mini.ai (installed) adds more: if/af = function,
ia/aa = argument. This is what makes vim feel telepathic."

  vim_drill "gut the string" \
"Change the wrong string to: ready
(ci' — single quotes this time — cursor anywhere on the line)" \
    "state = 'totally borked'" \
    "state = 'ready'"

  vim_drill "vanish the parens" \
"Delete the parenthesized aside ENTIRELY, parens included.
da( — delete around parens. Watch the stray space too (x)." \
    "keep this (not this) and this" \
    "keep this and this"

  vim_drill "paragraph punch" \
"Delete the entire middle paragraph (both lines) plus its blank
line: dap — delete around paragraph." \
    $'keep me\nkeep me too\n\ndelete this\ndelete this too\n\nkeep us\nkeep us too' \
    $'keep me\nkeep me too\n\nkeep us\nkeep us too'

  quiz "Delete a word including trailing space?" "daw" ""
  quiz "Change everything inside the { braces }?" "ci{|cib" ""
}

drills() {
  add_quiz "Save and quit?" ":wq|:x|zz"
  add_quiz "Quit without saving?" ":q!"
  add_quiz "Undo / redo?" "u ctrl-r|u and ctrl-r|u, ctrl-r"
  add_quiz "Top of file / bottom of file?" "gg g|gg and g|gg, g"
  add_quiz "Delete a whole line?" "dd"
  add_quiz "Change inside quotes?" "ci\"|ci'"
  add_quiz "Yank a line, paste below?" "yyp|yy p|yy then p"
  add_quiz "Repeat the last change?" "."
  add_quiz "Search the word under the cursor?" "*"
  add_quiz "Jump onto the next 'x' on the line?" "fx"
  add_quiz "Delete 3 lines in one command?" "3dd"
  add_quiz "Change inside parentheses?" "ci("
  add_quiz "Join next line onto this one?" "j|shift-j"
  add_quiz "Delete around a paragraph?" "dap"

  add_vim "speed: kill line 4" \
    "Delete line 4 (the BAD one). Fast: 4G dd or /BAD dd." \
    $'ok\nok\nok\nBAD\nok\nok' \
    $'ok\nok\nok\nok\nok'
  add_vim "speed: word swap" \
    "Change 'slow' to 'fast'." \
    "vim is slow today" \
    "vim is fast today"
  add_vim "speed: requote" \
    "Change the quoted string to: done" \
    'phase = "just starting"' \
    'phase = "done"'
  add_vim "speed: dedupe" \
    "One line appears twice in a row. Remove the duplicate." \
    $'alpha\nbeta\nbeta\ngamma\ndelta' \
    $'alpha\nbeta\ngamma\ndelta'
  add_vim "speed: top to bottom" \
    "Move the first line to the bottom (dd G p)." \
    $'tail me\none\ntwo\nthree' \
    $'one\ntwo\nthree\ntail me'
  add_vim "speed: triple TODO" \
    "Strip the trailing TODO from all three lines (daw + j + .)." \
    $'alpha TODO\nbeta TODO\ngamma TODO' \
    $'alpha\nbeta\ngamma'
  add_vim "speed: empty the parens" \
    "Delete everything inside the parentheses, keep the parens (di()." \
    "result = compute(all the wrong args)" \
    "result = compute()"
  add_vim "speed: duplicate" \
    "Duplicate the only line (yyp)." \
    "echo twice" \
    $'echo twice\necho twice'
}
