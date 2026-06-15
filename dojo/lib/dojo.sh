# dojo.sh — engine for the dotfiles dojo. Sourced by bin/dojo.
# Pure bash 3.2 (macOS stock). No dependencies beyond what the rice already
# uses (nvim, zsh, python3 for kitty JSON, aerospace CLI when present).
# Colors are plain ANSI-16 so the dojo follows the active vibe automatically.

DOJO_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/dojo"
SCORES="$DOJO_STATE/scores.tsv"
SANDBOX="$DOJO_STATE/sandbox"
mkdir -p "$DOJO_STATE" "$SANDBOX" "$DOJO_STATE/bin"

# ---------------------------------------------------------------- colors --
E=$'\033'
RS="$E[0m"; B="$E[1m"; DIM="$E[2m"; IT="$E[3m"
RED="$E[31m"; GRN="$E[32m"; YEL="$E[33m"; BLU="$E[34m"; MAG="$E[35m"; CYN="$E[36m"

# ----------------------------------------------------------------- state --
# scores.tsv: one "key<TAB>value" per line, last write wins.
state_get() {
  [ -f "$SCORES" ] || return 0
  awk -F'\t' -v k="$1" '$1==k{v=$2} END{if(v!="")print v}' "$SCORES"
}
state_set() {
  local tmp="$SCORES.tmp"
  { [ -f "$SCORES" ] && awk -F'\t' -v k="$1" '$1!=k' "$SCORES"
    printf '%s\t%s\n' "$1" "$2"; } > "$tmp" && mv "$tmp" "$SCORES"
}
state_bump() { local c; c=$(state_get "$1"); state_set "$1" $(( ${c:-0} + 1 )); }
state_min() { local c; c=$(state_get "$1"); if [ -z "$c" ] || [ "$2" -lt "$c" ]; then state_set "$1" "$2"; return 0; fi; return 1; }
state_max() { local c; c=$(state_get "$1"); if [ -z "$c" ] || [ "$2" -gt "$c" ]; then state_set "$1" "$2"; return 0; fi; return 1; }

# ------------------------------------------------------------------- ui --
hr()     { printf '  %s%s%s\n' "$DIM" "──────────────────────────────────────────────────────────" "$RS"; }
header() { clear; printf '\n  %s%s⛩  %s%s\n' "$B" "$MAG" "$1" "$RS"; hr; }
say()    { printf '%s\n' "$1" | while IFS= read -r l; do printf '  %s\n' "$l"; done; }
tip()    { printf '\n'; printf '%s\n' "$1" | while IFS= read -r l; do printf '  %s◆ %s%s\n' "$CYN" "$l" "$RS"; done; }
pause()  { printf '\n'; read -r -p "  ${DIM}[enter] ${RS}" _ </dev/tty || true; }
ok()     { printf '  %s✓ %s%s\n' "$GRN" "$1" "$RS"; }
bad()    { printf '  %s✗ %s%s\n' "$RED" "$1" "$RS"; }
stars_str() {
  case "${1:-0}" in
    3) printf '%s★★★%s' "$YEL" "$RS";;
    2) printf '%s★★%s☆%s' "$YEL" "$DIM" "$RS";;
    1) printf '%s★%s☆☆%s' "$YEL" "$DIM" "$RS";;
    *) printf '%s☆☆☆%s' "$DIM" "$RS";;
  esac
}

slugify() { printf '%s' "$1" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-'; }

# normalize a typed answer: lowercase, <> stripped, separators ( + -) removed
# so "ctrl-t", "ctrl+t", "Ctrl T", "<C-t>"-ish spellings all collide.
norm_ans() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[<>]//g' | tr -d ' +-'
}

# strip trailing whitespace and trailing blank lines (for vim drill compare)
norm_text() { sed -e 's/[[:space:]]*$//' | awk '{l[NR]=$0; if($0!="")last=NR} END{for(i=1;i<=last;i++)print l[i]}'; }

# does $1 (typed) match any |-separated alternate in $2? Also tries the
# whole string, so a literal "|" answer still works.
ans_match() {
  local got="$1" answers="$2" a
  [ "$(norm_ans "$got")" = "$(norm_ans "$answers")" ] && return 0
  local IFS='|'
  for a in $answers; do
    [ -n "$a" ] && [ "$(norm_ans "$got")" = "$(norm_ans "$a")" ] && return 0
  done
  return 1
}

# first alternate of an answer list, for reveals ("|" answers stay intact)
first_ans() { local f="${1%%|*}"; [ -n "$f" ] && printf '%s' "$f" || printf '%s' "$1"; }

shuffle_idx() { # $1 = count; prints 0..n-1 shuffled
  awk -v n="$1" 'BEGIN{srand(); for(i=0;i<n;i++) printf "%.6f\t%d\n", rand(), i}' | sort -n | cut -f2
}

# --------------------------------------------------------------- sandbox --
sandbox_reset() {
  rm -rf "$SANDBOX"
  mkdir -p "$SANDBOX"
  # Mirror the real editor's formatting so format-on-save (stylua via conform)
  # produces the same indent here as in actual projects. Without a stylua.toml
  # above the sandbox, stylua falls back to its 4-space default and drill
  # targets (written 2-space) stop matching.
  if [ -f "$HOME/.config/nvim/stylua.toml" ]; then
    cp "$HOME/.config/nvim/stylua.toml" "$SANDBOX/stylua.toml"
  else
    printf 'indent_type = "Spaces"\nindent_width = 2\n' > "$SANDBOX/stylua.toml"
  fi
}

# helper commands available inside shell_task subshells
write_helpers() {
  cat > "$DOJO_STATE/bin/dojo-check" <<'EOS'
#!/usr/bin/env bash
[ -n "$DOJO_CHECK" ] || { echo "no active dojo task"; exit 1; }
if bash -c "$DOJO_CHECK" >/dev/null 2>&1; then
  printf '\033[32m✓ task complete — type `exit` to return to the dojo\033[0m\n'
else
  printf '\033[31m✗ not yet\033[0m'
  [ -n "$DOJO_HINT" ] && printf '  \033[2m(dojo-hint for a hint)\033[0m'
  printf '\n'
  exit 1
fi
EOS
  cat > "$DOJO_STATE/bin/dojo-hint" <<'EOS'
#!/usr/bin/env bash
if [ -n "$DOJO_HINT" ]; then printf '\033[36m◆ %s\033[0m\n' "$DOJO_HINT"; else echo "no hint for this one"; fi
EOS
  cat > "$DOJO_STATE/bin/dojo-task" <<'EOS'
#!/usr/bin/env bash
printf '\033[33m%s\033[0m\n' "${DOJO_TASKTEXT:-no active dojo task}"
EOS
  chmod +x "$DOJO_STATE/bin/dojo-check" "$DOJO_STATE/bin/dojo-hint" "$DOJO_STATE/bin/dojo-task"
}

# ---------------------------------------------------------------- tasks --
# Per-lesson counters, reset by run_lesson.
TASK_N=0; TASK_OK=0; FIRST_OK=0; HINTS=0

brief() { printf '\n'; say "$1"; pause; }

# quiz "question" "answer|alt|alt2" ["explanation"]
quiz() {
  local q="$1" answers="$2" explain="${3:-}" tries=0 got matched=0
  TASK_N=$((TASK_N + 1))
  printf '\n  %s?%s  %s\n' "$B$YEL" "$RS" "$q"
  while [ "$tries" -lt 3 ]; do
    read -r -p "  ${YEL}❯${RS} " got </dev/tty || got=""
    tries=$((tries + 1))
    ans_match "$got" "$answers" && matched=1
    if [ "$matched" = 1 ]; then
      ok "correct"
      TASK_OK=$((TASK_OK + 1))
      [ "$tries" -eq 1 ] && FIRST_OK=$((FIRST_OK + 1))
      break
    fi
    [ "$tries" -lt 3 ] && bad "not quite — try again ($((3 - tries)) left)"
  done
  if [ "$matched" = 0 ]; then
    bad "answer: ${B}$(first_ans "$answers")${RS}"
  fi
  [ -n "$explain" ] && printf '  %s%s%s\n' "$DIM" "$explain" "$RS"
}

# guided "instructions" — do it for real, honor system (always passes)
guided() {
  TASK_N=$((TASK_N + 1)); TASK_OK=$((TASK_OK + 1)); FIRST_OK=$((FIRST_OK + 1))
  printf '\n  %s▸ TRY IT%s\n' "$B$BLU" "$RS"
  say "$1"
  printf '\n'
  read -r -p "  ${DIM}[enter] when you've done it ${RS}" _ </dev/tty || true
}

# shell_task "instructions" "check command" ["hint"]
# Drops the user into a real zsh inside the sandbox. dojo-check / dojo-hint /
# dojo-task are on PATH in there. Passes when the check command succeeds.
shell_task() {
  local inst="$1" check="$2" hint="${3:-}" first=1
  TASK_N=$((TASK_N + 1))
  write_helpers
  printf '\n  %s▸ SHELL TASK%s\n' "$B$GRN" "$RS"
  say "$inst"
  printf '\n'
  say "${DIM}A real shell opens in the practice sandbox. Inside it:
  dojo-task   reprint these instructions
  dojo-check  see if you got it
  dojo-hint   get a hint
  exit        come back here${RS}"
  while :; do
    printf '\n'
    read -r -p "  ${DIM}[enter] to drop in ${RS}" _ </dev/tty || true
    ( cd "$SANDBOX" && \
      DOJO_CHECK="$check" DOJO_HINT="$hint" DOJO_TASKTEXT="$inst" \
      RICE_HOME_SHOWN=1 _ZO_DOCTOR=0 PATH="$DOJO_STATE/bin:$PATH" zsh -i ) </dev/tty || true
    if ( cd "$SANDBOX" && eval "$check" ) >/dev/null 2>&1; then
      ok "task complete"
      TASK_OK=$((TASK_OK + 1))
      [ "$first" = 1 ] && FIRST_OK=$((FIRST_OK + 1))
      return 0
    fi
    bad "the check did not pass"
    local pick
    read -r -p "  ${DIM}(r)etry  (h)int  (s)kip ${RS}" pick </dev/tty || pick=s
    case "$pick" in
      h) HINTS=$((HINTS + 1)); [ -n "$hint" ] && tip "$hint" || tip "no hint for this one"; first=0;;
      s) return 1;;
      *) first=0;;
    esac
  done
}

# watch_task "instructions" "check command" ["hint"] [timeout_s]
# Live: polls the check once a second while the user performs the action
# (in another window/workspace). Great for kitty/aerospace.
watch_task() {
  local inst="$1" check="$2" hint="${3:-}" timeout="${4:-180}"
  TASK_N=$((TASK_N + 1))
  printf '\n  %s▸ LIVE TASK%s  %s(I am watching — go do it now)%s\n' "$B$MAG" "$RS" "$DIM" "$RS"
  say "$inst"
  printf '\n  %s…waiting   [h]int  [s]kip%s\n' "$DIM" "$RS"
  local t=0 k passed=0
  while [ "$t" -lt "$timeout" ]; do
    if ( eval "$check" ) >/dev/null 2>&1; then passed=1; break; fi
    k=""
    read -r -t 1 -n 1 k </dev/tty 2>/dev/null || true
    case "$k" in
      h|H) HINTS=$((HINTS + 1)); [ -n "$hint" ] && tip "$hint" || tip "no hint for this one";;
      s|S) break;;
    esac
    t=$((t + 1))
  done
  if [ "$passed" = 1 ]; then
    ok "detected — nice"
    TASK_OK=$((TASK_OK + 1)); FIRST_OK=$((FIRST_OK + 1))
    pause
    return 0
  fi
  bad "skipped (you can replay this lesson anytime)"
  return 1
}

# vim_drill "name" "instructions" "start text" "target text" [filename]
# Opens nvim on a prepared file; you pass when the saved file matches the
# target. Timed — best time per drill is kept forever.
vim_drill() {
  local name="$1" inst="$2" start="$3" target="$4" fname="${5:-drill.txt}"
  local id="best:drill:${CUR_LESSON_ID}:$(slugify "$name")" first=1
  TASK_N=$((TASK_N + 1))
  local best; best=$(state_get "$id")
  printf '\n  %s▸ VIM DRILL%s  %s%s%s' "$B$CYN" "$RS" "$B" "$name" "$RS"
  [ -n "$best" ] && printf '   %sbest: %ss%s' "$DIM" "$best" "$RS"
  printf '\n'
  say "$inst"
  while :; do
    printf '%s\n' "$start" > "$SANDBOX/$fname"
    printf '\n'
    read -r -p "  ${DIM}[enter] opens nvim — timer starts. :wq when done ${RS}" _ </dev/tty || true
    local t0 dt
    t0=$(date +%s)
    nvim "$SANDBOX/$fname" </dev/tty >/dev/tty 2>&1 || true
    dt=$(( $(date +%s) - t0 ))
    if [ "$(norm_text < "$SANDBOX/$fname")" = "$(printf '%s\n' "$target" | norm_text)" ]; then
      ok "matched in ${B}${dt}s${RS}"
      if state_min "$id" "$dt"; then
        [ -n "$best" ] && printf '  %s🏆 new personal best (was %ss)%s\n' "$YEL" "$best" "$RS"
      fi
      TASK_OK=$((TASK_OK + 1))
      [ "$first" = 1 ] && FIRST_OK=$((FIRST_OK + 1))
      return 0
    fi
    bad "not a match yet"
    printf '  %sexpected:%s\n' "$DIM" "$RS"
    printf '%s\n' "$target" | sed 's/^/      /'
    printf '  %syours:%s\n' "$DIM" "$RS"
    norm_text < "$SANDBOX/$fname" | sed 's/^/      /'
    local pick
    read -r -p "  ${DIM}(r)etry  (s)kip ${RS}" pick </dev/tty || pick=s
    [ "$pick" = s ] && return 1
    first=0
  done
}

# --------------------------------------------------------- kitty helpers --
# These resolve against the kitty window the dojo runs in (KITTY_WINDOW_ID).
kitty_tab_json() { # python expr context: tab containing our window
  kitty @ ls 2>/dev/null | python3 -c "
import json, sys, os
wid = int(os.environ.get('KITTY_WINDOW_ID', '-1'))
for ow in json.load(sys.stdin):
    for tab in ow['tabs']:
        if any(w['id'] == wid for w in tab['windows']):
            $1
            raise SystemExit
print('')
"
}
kitty_win_count()  { kitty_tab_json "print(len(tab['windows']))"; }
kitty_tab_layout() { kitty_tab_json "print(tab.get('layout',''))"; }
kitty_tab_title()  { kitty_tab_json "print(tab.get('title',''))"; }
kitty_tab_count() {
  kitty @ ls 2>/dev/null | python3 -c "
import json, sys, os
wid = int(os.environ.get('KITTY_WINDOW_ID', '-1'))
for ow in json.load(sys.stdin):
    if any(w['id'] == wid for t in ow['tabs'] for w in t['windows']):
        print(len(ow['tabs'])); raise SystemExit
print('')
"
}

# -------------------------------------------------------------- courses --
# A course is courses/<NN>-<slug>/course.sh defining:
#   COURSE_TITLE, COURSE_DESC, LESSONS=( "slug:Title" ... ),
#   lesson_<slug>() functions, and optionally drills() using add_quiz/add_vim.
course_dirs() { ls -d "$DOJO_ROOT"/courses/*/ 2>/dev/null; }
course_slug_of() { basename "$1" | sed 's/^[0-9]*-//'; }

load_course() { # $1 = dir
  COURSE_DIR="${1%/}"
  COURSE_SLUG=$(course_slug_of "$COURSE_DIR")
  COURSE_TITLE=""; COURSE_DESC=""; LESSONS=()
  unset -f drills 2>/dev/null
  . "$COURSE_DIR/course.sh"
}

course_progress() { # $1 = slug; echoes "done total stars"
  local done=0 total=0 stars=0 entry slug s
  total=${#LESSONS[@]}
  for entry in "${LESSONS[@]}"; do
    slug="${entry%%:*}"
    s=$(state_get "stars:lesson:$1/$slug")
    [ -n "$s" ] && { done=$((done + 1)); stars=$((stars + s)); }
  done
  echo "$done $total $stars"
}

run_lesson() { # $1 = lesson slug, $2 = lesson title
  CUR_LESSON_ID="$COURSE_SLUG/$1"
  TASK_N=0; TASK_OK=0; FIRST_OK=0; HINTS=0
  sandbox_reset
  header "$COURSE_TITLE ${DIM}/${RS}${B}${MAG} $2"
  local t0 dt
  t0=$(date +%s)
  "lesson_$1"
  dt=$(( $(date +%s) - t0 ))

  local stars=1
  if [ "$TASK_OK" -eq "$TASK_N" ] && [ "$TASK_N" -gt 0 ]; then
    if [ "$FIRST_OK" -eq "$TASK_N" ] && [ "$HINTS" -eq 0 ]; then stars=3; else stars=2; fi
  fi
  state_max "stars:lesson:$CUR_LESSON_ID" "$stars" >/dev/null || true
  state_min "best:lesson:$CUR_LESSON_ID" "$dt" >/dev/null || true
  state_bump "runs:lesson:$CUR_LESSON_ID"

  printf '\n'; hr
  printf '  %sLESSON COMPLETE%s  ' "$B$GRN" "$RS"; stars_str "$stars"
  printf '\n  tasks %s/%s · first-try %s · hints %s · %ss' "$TASK_OK" "$TASK_N" "$FIRST_OK" "$HINTS" "$dt"
  local prev; prev=$(state_get "best:lesson:$CUR_LESSON_ID")
  printf '   %sbest: %ss · runs: %s%s\n' "$DIM" "${prev:-$dt}" "$(state_get "runs:lesson:$CUR_LESSON_ID")" "$RS"
  pause
}

# --------------------------------------------------------------- arcade --
# Rapid-fire shuffled quiz round built from the course's drills(). One try
# per question, scored on accuracy + speed. High score persists.
AQ=(); AA=(); GV_NAME=(); GV_INST=(); GV_START=(); GV_TARGET=(); GV_FILE=()
add_quiz() { AQ[${#AQ[@]}]="$1"; AA[${#AA[@]}]="$2"; }
add_vim()  { GV_NAME[${#GV_NAME[@]}]="$1"; GV_INST[${#GV_INST[@]}]="$2"; GV_START[${#GV_START[@]}]="$3"; GV_TARGET[${#GV_TARGET[@]}]="$4"; GV_FILE[${#GV_FILE[@]}]="${5:-gym.txt}"; }

arcade_run() { # course already loaded
  AQ=(); AA=(); GV_NAME=(); GV_INST=(); GV_START=(); GV_TARGET=(); GV_FILE=()
  type drills >/dev/null 2>&1 || { say "this course has no arcade yet"; pause; return; }
  drills
  [ ${#AQ[@]} -gt 0 ] || { say "this course has no arcade questions yet"; pause; return; }

  local n=${#AQ[@]} take=10
  [ "$n" -lt "$take" ] && take=$n
  header "ARCADE ${DIM}/${RS}${B}${MAG} $COURSE_TITLE"
  local hi; hi=$(state_get "hi:arcade:$COURSE_SLUG")
  say "$take questions, ${B}one try each${RS}, the clock is running.
score = correct × 100 − seconds elapsed"
  [ -n "$hi" ] && say "${DIM}high score: $hi${RS}"
  printf '\n'
  read -r -p "  ${DIM}[enter] to start ${RS}" _ </dev/tty || true

  local i q correct=0 asked=0 got matched a t0 dt order
  t0=$(date +%s)
  order=$(shuffle_idx "$n")
  for i in $order; do
    [ "$asked" -ge "$take" ] && break
    asked=$((asked + 1))
    printf '\n  %s%s/%s%s  %s\n' "$DIM" "$asked" "$take" "$RS" "${AQ[$i]}"
    read -r -p "  ${YEL}❯${RS} " got </dev/tty || got=""
    if ans_match "$got" "${AA[$i]}"; then ok "yes"; correct=$((correct + 1))
    else bad "it was: ${B}$(first_ans "${AA[$i]}")${RS}"; fi
  done
  dt=$(( $(date +%s) - t0 ))
  local score=$(( correct * 100 - dt ))
  [ "$score" -lt 0 ] && score=0

  printf '\n'; hr
  printf '  %sSCORE: %s%s   %s%s/%s correct in %ss%s\n' "$B$YEL" "$score" "$RS" "$DIM" "$correct" "$take" "$dt" "$RS"
  if state_max "hi:arcade:$COURSE_SLUG" "$score"; then
    [ -n "$hi" ] && printf '  %s🏆 NEW HIGH SCORE (was %s)%s\n' "$YEL" "$hi" "$RS" \
                 || printf '  %s🏆 first score on the board%s\n' "$YEL" "$RS"
  else
    printf '  %shigh score still %s%s\n' "$DIM" "$hi" "$RS"
  fi
  state_bump "plays:arcade:$COURSE_SLUG"
  pause
}

# ------------------------------------------------------------------ gym --
# The vim gym: random timed vim drills pulled from every course's drills().
gym_run() {
  AQ=(); AA=(); GV_NAME=(); GV_INST=(); GV_START=(); GV_TARGET=(); GV_FILE=()
  local d
  for d in $(course_dirs); do
    ( :; ) # keep loop body non-empty for clarity
    load_course "$d"
    type drills >/dev/null 2>&1 && drills
  done
  local n=${#GV_NAME[@]}
  [ "$n" -gt 0 ] || { say "no gym drills registered yet"; pause; return; }
  local take=5; [ "$n" -lt "$take" ] && take=$n

  header "VIM GYM"
  local hi; hi=$(state_get "hi:gym")
  say "$take random edit drills, back to back, one timer.
Wrong or skipped costs 30s. score = ${take}00 − seconds − penalties"
  [ -n "$hi" ] && say "${DIM}high score: $hi${RS}"
  printf '\n'
  read -r -p "  ${DIM}[enter] to start ${RS}" _ </dev/tty || true

  sandbox_reset
  local i asked=0 misses=0 t0 dt order
  t0=$(date +%s)
  order=$(shuffle_idx "$n")
  for i in $order; do
    [ "$asked" -ge "$take" ] && break
    asked=$((asked + 1))
    printf '\n  %s%s/%s%s  %s%s%s\n' "$DIM" "$asked" "$take" "$RS" "$B" "${GV_NAME[$i]}" "$RS"
    say "${GV_INST[$i]}"
    local gfile="${GV_FILE[$i]:-gym.txt}"
    printf '%s\n' "${GV_START[$i]}" > "$SANDBOX/$gfile"
    read -r -p "  ${DIM}[enter] go ${RS}" _ </dev/tty || true
    nvim "$SANDBOX/$gfile" </dev/tty >/dev/tty 2>&1 || true
    if [ "$(norm_text < "$SANDBOX/$gfile")" = "$(printf '%s\n' "${GV_TARGET[$i]}" | norm_text)" ]; then
      ok "clean"
    else
      misses=$((misses + 1))
      bad "miss (+30s) — expected:"
      printf '%s\n' "${GV_TARGET[$i]}" | sed 's/^/      /'
    fi
  done
  dt=$(( $(date +%s) - t0 ))
  local score=$(( take * 100 - dt - misses * 30 ))
  [ "$score" -lt 0 ] && score=0

  printf '\n'; hr
  printf '  %sGYM SCORE: %s%s   %s%ss, %s misses%s\n' "$B$YEL" "$score" "$RS" "$DIM" "$dt" "$misses" "$RS"
  if state_max "hi:gym" "$score"; then
    [ -n "$hi" ] && printf '  %s🏆 NEW HIGH SCORE (was %s)%s\n' "$YEL" "$hi" "$RS" \
                 || printf '  %s🏆 first score on the board%s\n' "$YEL" "$RS"
  fi
  state_bump "plays:gym"
  pause
}

# ---------------------------------------------------------------- menus --
course_menu() { # course already loaded
  while :; do
    header "$COURSE_TITLE"
    say "$COURSE_DESC"
    printf '\n'
    local i=0 entry slug title s best
    for entry in "${LESSONS[@]}"; do
      i=$((i + 1))
      slug="${entry%%:*}"; title="${entry#*:}"
      s=$(state_get "stars:lesson:$COURSE_SLUG/$slug")
      best=$(state_get "best:lesson:$COURSE_SLUG/$slug")
      printf '   %s%2d)%s %-38s ' "$B" "$i" "$RS" "$title"
      stars_str "${s:-0}"
      [ -n "$best" ] && printf '  %s%ss%s' "$DIM" "$best" "$RS"
      printf '\n'
    done
    printf '\n'
    local hi; hi=$(state_get "hi:arcade:$COURSE_SLUG")
    printf '   %s a)%s arcade — rapid-fire quiz %s%s%s\n' "$B" "$RS" "$DIM" "${hi:+(high: $hi)}" "$RS"
    printf '   %s q)%s back\n\n' "$B" "$RS"
    local pick
    read -r -p "  ${MAG}❯${RS} " pick </dev/tty || return
    case "$pick" in
      q|Q|'') return;;
      a|A) arcade_run;;
      *)
        if [ "$pick" -ge 1 ] 2>/dev/null && [ "$pick" -le "${#LESSONS[@]}" ]; then
          entry="${LESSONS[$((pick - 1))]}"
          run_lesson "${entry%%:*}" "${entry#*:}"
        fi;;
    esac
  done
}

stats_screen() {
  header "STATS"
  local d done total stars
  for d in $(course_dirs); do
    load_course "$d"
    set -- $(course_progress "$COURSE_SLUG")
    done=$1; total=$2; stars=$3
    printf '   %-34s %s/%s lessons   %s★ %-3s%s' "$COURSE_TITLE" "$done" "$total" "$YEL" "$stars" "$RS"
    local hi; hi=$(state_get "hi:arcade:$COURSE_SLUG")
    [ -n "$hi" ] && printf '  %sarcade %s%s' "$DIM" "$hi" "$RS"
    printf '\n'
  done
  printf '\n'
  local g; g=$(state_get "hi:gym")
  [ -n "$g" ] && printf '   %svim gym high score: %s%s\n' "$YEL" "$g" "$RS"
  printf '   %sstate: %s%s\n' "$DIM" "$SCORES" "$RS"
  pause
}

main_menu() {
  while :; do
    header "DOTFILES DOJO"
    say "Learn your setup by doing. Lessons are replayable — chase ★★★
and beat your times. ${DIM}(numbers pick, q quits)${RS}"
    printf '\n'
    local d i=0 dirs="" done total stars
    for d in $(course_dirs); do
      i=$((i + 1))
      dirs="$dirs $d"
      load_course "$d"
      set -- $(course_progress "$COURSE_SLUG")
      done=$1; total=$2; stars=$3
      printf '   %s%2d)%s %-34s' "$B" "$i" "$RS" "$COURSE_TITLE"
      if [ "$done" -eq "$total" ] && [ "$total" -gt 0 ]; then
        printf ' %s%s/%s ★%s%s\n' "$GRN" "$done" "$total" "$stars" "$RS"
      elif [ "$done" -gt 0 ]; then
        printf ' %s%s/%s ★%s%s\n' "$YEL" "$done" "$total" "$stars" "$RS"
      else
        printf ' %s%s/%s%s\n' "$DIM" "$done" "$total" "$RS"
      fi
    done
    printf '\n'
    local g; g=$(state_get "hi:gym")
    printf '   %s g)%s vim gym — random timed drills %s%s%s\n' "$B" "$RS" "$DIM" "${g:+(high: $g)}" "$RS"
    printf '   %s s)%s stats\n' "$B" "$RS"
    printf '   %s q)%s quit\n\n' "$B" "$RS"
    local pick
    read -r -p "  ${MAG}❯${RS} " pick </dev/tty || return
    case "$pick" in
      q|Q|'') return;;
      g|G) gym_run;;
      s|S) stats_screen;;
      *)
        if [ "$pick" -ge 1 ] 2>/dev/null && [ "$pick" -le "$i" ]; then
          set -- $dirs
          eval "d=\${$pick}"
          load_course "$d"
          course_menu
        fi;;
    esac
  done
}
