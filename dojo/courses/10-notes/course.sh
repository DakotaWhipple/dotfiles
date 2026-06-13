# Course: notes — the zk vault at ~/notes and every way into it.
COURSE_TITLE="Notes: Capture to Knowledge"
COURSE_DESC="Your vault is plain markdown at ~/notes, indexed by zk.
Capture from anywhere, find anything, link it into knowledge.
(Take notes ON these dojo lessons — that is the whole point.)"

LESSONS=(
  "capture:Zero-friction capture (alt+n, jot)"
  "createfind:Creating and finding notes"
  "invim:Notes inside neovim (space n)"
  "linking:Links, backlinks, and the method"
)

lesson_capture() {
  brief "Rule one of note-taking: if capture has friction, you stop
capturing. So this setup gives you two zero-friction paths into
today's journal note (~/notes/journal/$(date +%F).md):

  jot some thought     from any shell — timestamps it under ## Log
  alt+n                from ANYWHERE on the machine — tiny popup,
                       type, enter, gone (bin/note-capture)

Both append to the same daily log. The journal is your inbox."

  # baselines so a replay (word already in today's journal) can't self-pass
  local jbase nbase
  jbase=$(grep -ci dojo "$HOME/notes/journal/$(date +%F).md" 2>/dev/null); jbase=${jbase:-0}
  nbase=$(grep -ci ninja "$HOME/notes/journal/$(date +%F).md" 2>/dev/null); nbase=${nbase:-0}

  shell_task "Use jot to log a thought that contains the word dojo.
(e.g.  jot starting the dojo)" \
    '[ "$(grep -ci dojo "$HOME/notes/journal/$(date +%F).md" 2>/dev/null)" -gt '"$jbase"' ] 2>/dev/null' \
    "jot starting the dojo"

  watch_task "Now the global one: press alt+n right now (anywhere),
type a thought containing the word ninja, hit enter." \
    '[ "$(grep -ci ninja "$HOME/notes/journal/$(date +%F).md" 2>/dev/null)" -gt '"$nbase"' ] 2>/dev/null' \
    "alt+n is bound in aerospace.toml to bin/note-capture"

  quiz "Capture a note from anywhere on the machine?" "alt-n" \
    "it lands in today's journal under ## Log, timestamped"
}

lesson_createfind() {
  brief "Three tiny commands (in ~/dotfiles/bin) cover the vault:

  note            fuzzy-pick any note (most recent first)
  note My Title   CREATE a note titled 'My Title' and open it
  notes WORD      full-text search, then pick and open

Notes are files: a note titled 'Dojo Scratch' becomes
~/notes/dojo-scratch.md. No app, no lock-in, just markdown."

  shell_task "Create a note titled exactly:  Dojo Scratch
(with the note command). Write one line about what you have
learned so far, then save and quit (:wq)." \
    '[ -f "$HOME/notes/dojo-scratch.md" ]' \
    "note Dojo Scratch"

  guided "Now find it again the other way: run  notes scratch
— full-text search — open it, then quit nvim."

  quiz "Command to create a note titled 'Big Idea'?" "note big idea|note Big Idea" ""
  quiz "Command for full-text search across all notes?" "notes" \
    "note picks by title/recency, notes greps inside everything"
}

lesson_invim() {
  brief "Inside neovim, space n is the notes prefix (zk-nvim):

  space n n   new note (asks for a title)
  space n d   today's daily note
  space n f   find notes (fuzzy, recent first)
  space n s   full-text search
  space n b   backlinks — who links HERE?
  space n t   browse tags

On any [[wiki link]]:  enter follows it,  K previews it
without leaving the file."

  guided "Open nvim anywhere, press space n f, fuzzy-find your
'Dojo Scratch' note, open it. Leave nvim open for the next step."

  guided "Press space n d — today's daily note. Your jot and alt+n
captures from the first lesson should be sitting under ## Log."

  quiz "Find notes from inside nvim?" "space n f|leader n f|spacenf|leadernf" ""
  quiz "Open today's daily note?" "space n d|leader n d|spacend|leadernd" ""
  quiz "Follow a [[wiki link]] under the cursor?" "enter|cr|return" \
    "and K previews the linked note in a floating window"
}

lesson_linking() {
  brief "The method (zettelkasten, minus the ceremony):

  1. journal = inbox. jot everything; review it later.
  2. when a theme keeps showing up, promote it: one note,
     one idea, with a descriptive title.
  3. LINK MORE THAN FEELS NATURAL. [[other note]] while typing —
     the zk LSP autocompletes titles after [[
  4. backlinks (space n b) make links pay off: every note knows
     who references it. That is how notes become a graph, not a pile.
  5. #tags for broad buckets, links for real relationships."

  shell_task "Open your scratch note (notes scratch) and add a line
containing a wiki link:  [[Dojo Training Log]]
Type [[ and let the LSP offer completions. Save and quit." \
    'grep -q "\[\[" "$HOME/notes/dojo-scratch.md" 2>/dev/null' \
    "in nvim, insert mode, type: see also [[Dojo Training Log]]"

  quiz "Which view answers 'what links TO this note'?" "backlinks|space n b|spacenb" ""

  brief "Habit to build starting today: every dojo lesson, jot one
line about what clicked. Friday, open the week's journal entries
(zk recent in a shell, or space n f) and promote anything worth
keeping into a real note. That loop — capture, review, promote,
link — is the entire system."
}

drills() {
  add_quiz "Capture a thought from anywhere (key)?" "alt-n"
  add_quiz "Log a timestamped line from the shell?" "jot"
  add_quiz "Create a note titled X from the shell?" "note x|note X"
  add_quiz "Full-text search the vault from the shell?" "notes"
  add_quiz "New note inside nvim?" "space n n|leadernn|spacenn"
  add_quiz "Daily note inside nvim?" "space n d|leadernd|spacend"
  add_quiz "Find notes inside nvim?" "space n f|leadernf|spacenf"
  add_quiz "Backlinks inside nvim?" "space n b|leadernb|spacenb"
  add_quiz "Follow a wiki link under the cursor?" "enter|cr"
  add_quiz "Preview a wiki link without leaving?" "k|shift-k"
  add_quiz "Where does jot write? (journal/...)" "today|daily|journal"
  add_quiz "Wiki link syntax: two opening...?" "[[|brackets"
}
