# dojo ⛩

Interactive trainer for this whole setup. Run `dojo` in kitty.

- **Lessons** are hands-on: real shells in a sandbox, real nvim with
  timed drills, and *live* tasks where the dojo watches your actual
  kitty layout / aerospace workspaces and passes when it sees the
  real thing.
- **Replayable**: every lesson keeps stars (★★★ = all tasks, first
  try, no hints), a best time, and a run count. Drills keep personal
  bests forever.
- **Arcade** (per course): 10 shuffled questions, one try each,
  scored on accuracy + speed. High score persists.
- **Vim gym** (`dojo gym`): 5 random timed edit drills pulled from
  every course. One timer, misses cost 30s.

```
dojo              menu
dojo vim-core     jump straight to a course (dojo list shows slugs)
dojo gym          random timed vim drills
dojo stats        progress + high scores
dojo reset        wipe progress
```

State lives in `~/.local/state/dojo/scores.tsv` (plain TSV).
The sandbox for shell tasks is `~/.local/state/dojo/sandbox`.

## Layout

```
dojo/
  lib/dojo.sh          engine: ui, state, task types, arcade, gym
  courses/NN-slug/
    course.sh          one file per course: metadata + lessons + drills
```

Pure bash 3.2 (macOS stock), zero dependencies beyond what the rice
already uses. ANSI-16 colors only, so the dojo follows the active
vibe automatically.

## Adding a course (rust, spanish, anything)

Create `courses/90-rust/course.sh`:

```bash
COURSE_TITLE="Rust Basics"
COURSE_DESC="One paragraph shown at the top of the course menu."

LESSONS=(
  "ownership:Ownership and borrowing"   # slug:Title
)

lesson_ownership() {        # lesson_<slug>
  brief "Teaching text. Shown, then [enter]."
  quiz "Question?" "answer|alternate answer" "optional explanation"
  shell_task "Do X in the sandbox shell." 'check command' "hint"
  watch_task "Do X anywhere; I poll until true." 'check command' "hint"
  vim_drill "name" "instructions" $'start\ntext' $'target\ntext' "file.rs"
  guided "Do X for real, press enter when done."   # honor system
}

drills() {                  # optional: feeds arcade + gym
  add_quiz "Question?" "answer|alt"
  add_vim "name" "instructions" $'start' $'target' "file.rs"
}
```

Rules of thumb:

- Lesson slugs must be valid bash function-name parts; keep them
  unique within the course.
- `shell_task` checks run with cwd = sandbox; `watch_task` checks
  are polled ~1/s and may use the helpers `kitty_win_count`,
  `kitty_tab_count`, `kitty_tab_layout`, `kitty_tab_title`, or the
  `aerospace` CLI.
- Inside a shell task the user has `dojo-task`, `dojo-check`,
  `dojo-hint` on PATH.
- Answers are matched case-insensitively with `<>` stripped and
  space/`+` treated as `-`, so list generous alternates.
- Course text is sourced bash: escape `` ` `` and `$` inside
  double quotes.
