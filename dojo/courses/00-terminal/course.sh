# Course: terminal survival — the shell itself, plus this rice's upgrades.
COURSE_TITLE="Terminal Survival"
COURSE_DESC="The shell is the home base for everything else. Moving around,
files, reading, pipes — then the superpowers this setup adds on top."

LESSONS=(
  "orient:Where am I? (pwd, ls, cd)"
  "files:Making and moving files"
  "peek:Looking inside files"
  "pipes:Pipes — combining commands"
  "powerups:This rice's superpowers"
)

lesson_orient() {
  brief "A shell is a conversation: you type a command (maybe with
arguments), press enter, it answers. Three commands cover 90% of
getting around:

  pwd      print working directory — where am I?
  ls       list what is here (yours is eza, with icons)
  cd DIR   change directory. cd .. goes up, plain cd goes home.

Press TAB constantly — it completes file and directory names.
Half of terminal speed is just tab completion."

  quiz "Which command prints the directory you are in?" "pwd" \
    "pwd = print working directory"

  mkdir -p "$SANDBOX/castle/tower/attic" "$SANDBOX/castle/cellar" "$SANDBOX/garden"

  shell_task "Somewhere under castle/ there is an attic.
Get there with cd (use TAB!), then leave proof:  touch flag.txt" \
    '[ -f castle/tower/attic/flag.txt ]' \
    "cd castle/tower/attic   then   touch flag.txt"

  tip "ll = long list with git status, la = include hidden files,
lt = tree view. These are eza aliases from zsh/rice.zsh."

  quiz "How do you go UP one directory?" "cd ..|cd.." \
    "and 'cd -' bounces back to wherever you just were"
}

lesson_files() {
  brief "The file verbs:

  mkdir DIR        make a directory (mkdir -p makes parents too)
  touch FILE       make an empty file
  cp A B           copy (cp -r for directories)
  mv A B           move — also how you RENAME
  rm FILE          delete (rm -r DIR for directories — no trash!)"

  printf 'groceries\nplans\n' > "$SANDBOX/notes_old.txt"

  shell_task "There is a file called notes_old.txt here.
Rename it to notes.txt" \
    '[ -f notes.txt ] && [ ! -e notes_old.txt ]' \
    "mv notes_old.txt notes.txt"

  shell_task "Make a directory called archive, and put a COPY of
notes.txt inside it (the original should stay put)." \
    '[ -f archive/notes.txt ] && [ -f notes.txt ]' \
    "mkdir archive   then   cp notes.txt archive/"

  touch "$SANDBOX/junk.tmp"

  shell_task "A file named junk.tmp appeared. Delete it." \
    '[ ! -e junk.tmp ]' \
    "rm junk.tmp"

  quiz "Copy a whole directory: cp needs which flag?" "-r|cp -r|-R" \
    "r for recursive — same flag rm needs to delete a directory"
}

lesson_peek() {
  awk 'BEGIN{for(i=1;i<=200;i++){ if(i==137) print "secret: tangerine"; else print "log line " i }}' \
    > "$SANDBOX/big.log"

  brief "Reading files without opening an editor:

  cat FILE        dump it (yours is bat: syntax colors, line numbers)
  less FILE       page through big files — q quits, /word searches
  head -5 FILE    first 5 lines        tail -5 FILE   last 5
  wc -l FILE      count lines
  grep WORD FILE  print only matching lines"

  shell_task "big.log has 200 lines. ONE of them starts with 'secret:'.
Find the secret word and write it into answer.txt
(echo theword > answer.txt)" \
    'grep -q tangerine answer.txt 2>/dev/null' \
    "grep secret big.log   then   echo tangerine > answer.txt"

  quiz "Show only the FIRST 5 lines of a file?" "head -5|head -n 5|head -n5" \
    "tail does the end; tail -f follows a growing log live"

  quiz "Count the lines in a file?" "wc -l" \
    "wc = word count; -l switches it to lines"
}

lesson_pipes() {
  brief "The big idea of Unix: small tools, chained.

  |    pipe — send output of one command INTO the next
  >    redirect output into a file (overwrites)
  >>   append to a file

  sort file | uniq | wc -l
  ...sorts the lines, drops duplicates, counts what is left.
One sentence, three programs."

  printf 'apple\nbanana\napple\ncherry\nbanana\napple\nkiwi\n' > "$SANDBOX/fruits.txt"

  shell_task "fruits.txt has duplicate lines. Count how many UNIQUE
fruits there are, and put just the number in count.txt" \
    '[ "$(tr -d "[:space:]" < count.txt 2>/dev/null)" = "4" ]' \
    "sort fruits.txt | uniq | wc -l > count.txt"

  quiz "Which symbol pipes one command into another?" "|" ""
  quiz "Append to a file instead of overwriting?" ">>" ""

  tip "grep composes too: history | grep ssh, ls | grep .png —
once you think in pipes, the terminal stops feeling like typing
commands and starts feeling like plumbing."
}

lesson_powerups() {
  brief "Your zsh (zsh/rice.zsh) upgrades the basics:

  cd       is zoxide — it LEARNS. After visiting ~/notes once,
           'cd notes' works from anywhere. Frecency, not paths.
  ctrl-r   atuin — full-text search of every command you ever ran
  ctrl-t   fzf — fuzzy-pick a file path into your command line
  cat      is bat (colors)     ls/ll/la/lt   are eza
  y        opens yazi, the file manager — quit and the shell
           has cd'd to wherever you were"

  guided "In your normal shell (this works here too): press ctrl-r,
type a few letters of some command you ran today, watch atuin find
it. Esc to cancel."

  guided "Type 'cd not' and press enter (zoxide should jump you to
~/notes). Then 'cd -' to bounce back."

  quiz "Fuzzy-pick a file path into the command line?" "ctrl-t" ""
  quiz "Search your entire shell history?" "ctrl-r" \
    "atuin syncs context too — directory, exit code, duration"
  quiz "Which single letter opens the yazi file manager?" "y" \
    "navigate with hjkl, q quits and the shell follows you there"
}

drills() {
  add_quiz "Print the current directory?" "pwd"
  add_quiz "Go up one directory?" "cd .."
  add_quiz "Bounce back to the previous directory?" "cd -"
  add_quiz "Rename file a to b?" "mv a b"
  add_quiz "Flag to copy/remove a whole directory?" "-r|-R"
  add_quiz "Count lines in a file?" "wc -l"
  add_quiz "Pipe symbol?" "|"
  add_quiz "Append output to a file?" ">>"
  add_quiz "First 5 lines of a file?" "head -5|head -n 5|head -n5"
  add_quiz "Print only lines matching a word?" "grep"
  add_quiz "Make nested directories in one go: mkdir flag?" "-p|mkdir -p"
  add_quiz "Fuzzy file picker keybind?" "ctrl-t"
  add_quiz "Full-text shell history search keybind?" "ctrl-r"
  add_quiz "Open the yazi file manager?" "y"
}
