# Course: zsh — the shell as an editor, history, and your config.
COURSE_TITLE="Zsh: A Shell That Edits"
COURSE_DESC="Your command line IS a vim buffer (bindkey -v). Plus the
history machine, fuzzy everything, and how to make the shell yours."

LESSONS=(
  "viline:Vim on the command line"
  "history:History is a database"
  "fuzzy:Fuzzy everything"
  "config:Owning rice.zsh"
)

lesson_viline() {
  brief "Your zsh runs vi-mode (bindkey -v in zsh/rice.zsh).
The command line is a one-line vim buffer:

  esc          NORMAL mode — the prompt arrow flips to ❮
  ciw, dw, x   edit the command like text
  0 / \$        jump to start / end          b/w   hop words
  cc           wipe the line and retype
  i / a        back to typing

In insert mode the classics still work: ctrl+a start,
ctrl+e end. Typo at the START of a long command? esc 0 cw."

  guided "Type (do not run):  echo tihs is a lnog command
Press esc — see the prompt flip to ❮. Now: 0 to the start,
w to hop onto 'tihs', cw to fix it, esc, fix 'lnog' the same
way (fl finds it, or w w w). Enter runs it."

  quiz "Switch the command line to NORMAL mode?" "esc|escape" ""
  quiz "Wipe the whole line and start over (normal mode)?" "cc|0 shift-d" ""
}

lesson_history() {
  brief "Every command you run is in the database (atuin):

  ctrl+r       search ALL history, full-text, ranked
  up arrow     plain last-commands scrolling
  !!           the entire previous command
  !\$           just the LAST ARGUMENT of the previous command

!\$ is the sleeper hit:
  mkdir -p some/deep/dir   then   cd !\$
  cat some/long/path.txt   then   nvim !\$"

  shell_task "Two commands:
  1)  echo one two three
  2)  touch !\$        (creates a file named after the LAST arg)
Which file appeared? Check with ls." \
    '[ -f three ]' \
    'the !$ expands to: three'

  quiz "Search all shell history?" "ctrl-r" ""
  quiz "Reuse the last argument of the previous command?" "!\$" ""
}

lesson_fuzzy() {
  brief "Three fuzzy layers, all themed to your vibe:

  ctrl+t      fzf: fuzzy-pick file path(s) into the command line
              (type 'nvim ' first, then ctrl+t — instant open)
  cd PART     zoxide: cd by fragment of anywhere you have been —
              'cd dot' from anywhere lands in ~/dotfiles
  ctrl+r      atuin (you just met it)

And yazi (y) when you want to LOOK at the filesystem while
deciding — quit and your shell has followed you."

  guided "Type:  nvim   (with a trailing space) then ctrl+t.
Fuzzy-type some config name (kitty, rice...), enter — the path
lands on your command line. Run it, look around, quit."

  guided "From this sandbox shell or any shell: cd dot
(zoxide jumps to ~/dotfiles), then cd -, then cd not (~/notes).
Frecency means YOUR most-used dirs win ties."

  quiz "Fuzzy-insert a file path?" "ctrl-t" ""
  quiz "Jump to ~/dotfiles from anywhere?" "cd dot|cd dotfiles|z dot" ""
}

lesson_config() {
  brief "Everything in this course lives in ONE file:
~/dotfiles/zsh/rice.zsh — sourced by ~/.zshrc. The pattern:

  alias ll='eza ... -l'         a shorthand
  function y() { ... }          a tiny program
  export PATH=\"...:\$PATH\"       where commands are found

Add an alias, open a NEW shell (or source ~/.zshrc), done.
Your future aliases go right there, next to the others."

  printf '# my zsh config (practice copy)\n' > "$SANDBOX/myrc.zsh"

  shell_task "There is a practice file here, myrc.zsh. Open it in
nvim and add an alias so that 'st' runs 'jj st'. The shape:
  alias st='jj st'
Save and quit." \
    "grep -q \"alias st='jj st'\" myrc.zsh" \
    "nvim myrc.zsh — add: alias st='jj st'"

  quiz "Env var pointing at your dotfiles repo?" "dotfiles|\$dotfiles" \
    "echo \$DOTFILES — set in rice.zsh, used everywhere"
  quiz "Which file do your aliases actually live in?" "rice.zsh|zsh/rice.zsh|~/dotfiles/zsh/rice.zsh" ""

  brief "Worth knowing: because ~/dotfiles/bin is on PATH (rice.zsh
does this), any executable file you drop in there is instantly a
command. That is where note, jot, theme, and friends live — and
where the scripting course will send you."
}

drills() {
  add_quiz "Command line to normal mode?" "esc"
  add_quiz "Search all history?" "ctrl-r"
  add_quiz "Last argument of previous command?" "!\$"
  add_quiz "Whole previous command?" "!!"
  add_quiz "Fuzzy file path picker?" "ctrl-t"
  add_quiz "Jump to a dir by fragment (tool name)?" "zoxide"
  add_quiz "Which file holds your aliases?" "rice.zsh"
  add_quiz "Make changes to rice.zsh take effect?" "source ~/.zshrc|new shell|source"
  add_quiz "Start-of-line / end-of-line in insert mode?" "ctrl-a ctrl-e|ctrl-a and ctrl-e|ctrl-a, ctrl-e"
  add_quiz "File manager that cd follows on quit?" "yazi|y"
}
