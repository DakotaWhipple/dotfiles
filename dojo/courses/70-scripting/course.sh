# Course: bash scripting — from first script to shipping tools in bin/.
COURSE_TITLE="Bash Scripting"
COURSE_DESC="A script is just commands in a file. By the end of this
course you write real tools and put them on your PATH — the same way
note, jot, and theme were built."

LESSONS=(
  "hello:Your first executable"
  "vars:Variables and arguments"
  "logic:Tests, loops, exit codes"
  "robust:Scripts that do not lie"
  "ship:Ship it to bin/"
)

lesson_hello() {
  brief "Three ingredients make a file a program:

  1. a shebang first line:   #!/usr/bin/env bash
     (says WHICH interpreter runs this file)
  2. permission to execute:  chmod +x file
  3. a path to invoke it:    ./file   (./ = right here)

That is the entire magic trick. Everything in ~/dotfiles/bin
is just this."

  shell_task "Write hello.sh (nvim hello.sh) that prints exactly:
  hello dojo
Give it the shebang, chmod +x it, test with ./hello.sh" \
    '[ -x hello.sh ] && [ "$(./hello.sh 2>/dev/null)" = "hello dojo" ]' \
    'two lines: #!/usr/bin/env bash then echo "hello dojo" — then chmod +x hello.sh'

  quiz "Make a file executable?" "chmod +x" ""
  quiz "First line of every bash script?" "#!/usr/bin/env bash|shebang" \
    "env finds bash on PATH — more portable than hardcoding /bin/bash"
}

lesson_vars() {
  brief "Data in and out:

  name=\"koda\"        no spaces around = (really)
  echo \"\$name\"       ALWAYS double-quote your variables
  \$1 \$2 ...          the script's arguments    \$@   all of them
  \$(command)         capture a command's output:
  today=\$(date +%A)

Quoting rule of thumb: \"\$var\" everywhere, and you skip a whole
genre of bugs (spaces in filenames)."

  shell_task "Write greet.sh so that:
  ./greet.sh world   prints   hello, world
  ./greet.sh koda    prints   hello, koda" \
    '[ -x greet.sh ] && [ "$(./greet.sh world 2>/dev/null)" = "hello, world" ] && [ "$(./greet.sh koda 2>/dev/null)" = "hello, koda" ]' \
    'echo "hello, $1"   — and chmod +x greet.sh'

  quiz "All arguments, properly quoted?" "\"\$@\"|\$@" ""
  quiz "Capture output of a command into a variable?" "\$(command)|\$()" ""
}

lesson_logic() {
  brief "Every command ends with an exit code: 0 = success.
\$? holds the last one. Logic is built on that:

  if [ -f file ]; then ... fi      -f exists?  -d dir?  -z empty?
  cmd && echo ok || echo no        chaining on success/failure
  for f in *.txt; do ... done      loop over files

[ ] is a COMMAND named test — it needs those spaces inside."

  printf 'a\n' > "$SANDBOX/one.txt"; printf 'b\n' > "$SANDBOX/two.txt"; printf 'c\n' > "$SANDBOX/three.txt"
  printf 'x\n' > "$SANDBOX/decoy.log"

  shell_task "Write count.sh that prints HOW MANY .txt files are in
the current directory (there are 3 here, plus a decoy .log)." \
    '[ -x count.sh ] && [ "$(./count.sh 2>/dev/null | tr -d "[:space:]")" = "3" ]' \
    "ls *.txt | wc -l   — or a for loop with a counter"

  quiz "Test whether a file exists (the flag)?" "-f" ""
  quiz "Exit code of the last command?" "\$?" ""
}

lesson_robust() {
  brief "Top of every serious script (see bin/jot, bin/note):

  set -euo pipefail
   -e   die on the first failing command
   -u   die on undefined variables (typo insurance)
   -o pipefail   a pipe fails if ANY stage fails

Without it, bash shrugs past errors and 'succeeds'.
Also: read data line by line with
  while IFS= read -r line; do ... done"

  shell_task "Write shout.sh: reads stdin, prints it UPPERCASED.
  echo hi | ./shout.sh     →   HI
(tr a-z A-Z is your friend. Include set -euo pipefail.)" \
    '[ -x shout.sh ] && [ "$(echo hi | ./shout.sh 2>/dev/null)" = "HI" ] && grep -q "set -euo pipefail" shout.sh' \
    "after the shebang and set line, just: tr a-z A-Z"

  quiz "Flag that stops the script on the first error?" "-e|set -e" ""
  quiz "Flag that catches undefined variables?" "-u|set -u" ""

  tip "Install shellcheck (brew install shellcheck) — nvim already
lints bash with it when present, right in the gutter."
}

lesson_ship() {
  brief "Shipping = putting the script on your PATH.
~/dotfiles/bin is already there, so:

  1. write tool.sh in the sandbox, test it
  2. mv it to ~/dotfiles/bin/tool   (no .sh — commands have
     clean names: note, jot, theme)
  3. open a new shell: tool   just works, from anywhere

Study the house style first: bat ~/dotfiles/bin/jot
— shebang, comment header with usage, set -euo pipefail."

  shell_task "Capstone, in the sandbox: write a script named exactly
  today
(no extension) that prints the weekday (date +%A), executable,
with set -euo pipefail and a one-line comment header saying what
it does. Test: ./today" \
    '[ -x today ] && [ "$(./today 2>/dev/null)" = "$(date +%A)" ] && grep -q "set -euo pipefail" today && grep -q "^#.*today" today' \
    'lines: shebang / # today — prints the weekday / set -euo pipefail / date +%A'

  guided "If you like it, actually ship it:
  mv today ~/dotfiles/bin/   then open a new shell and run: today
(and later, let jj record it: jj st in ~/dotfiles)"

  quiz "Where do personal tools live to be on PATH?" "~/dotfiles/bin|dotfiles/bin|bin" ""
  quiz "Which existing script is the best template?" "jot|note|bin/jot|bin/note" \
    "small, commented, set -euo pipefail — copy its bones"
}

drills() {
  add_quiz "Shebang for bash?" "#!/usr/bin/env bash"
  add_quiz "Make executable?" "chmod +x"
  add_quiz "Run a script in this directory?" "./script|./"
  add_quiz "First argument?" "\$1"
  add_quiz "All arguments quoted?" "\"\$@\"|\$@"
  add_quiz "Capture command output?" "\$()|\$(command)"
  add_quiz "Die on first error (full line)?" "set -euo pipefail|set -e"
  add_quiz "Test a directory exists (flag)?" "-d"
  add_quiz "Exit code of last command?" "\$?"
  add_quiz "Loop over txt files?" "for f in *.txt"
  add_quiz "Read stdin line by line?" "while read|while IFS= read -r line"
  add_quiz "Linter for shell scripts?" "shellcheck"
}
