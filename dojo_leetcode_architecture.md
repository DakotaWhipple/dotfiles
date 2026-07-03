# Dojo LeetCode Neovim Plugin Architecture (v5)

**Goal:** "what's a two sum?" → Anthropic-senior-level interviewing, trained inside the best neovim setup possible. Doublelift mechanics, Faker macro: mechanics matter but are secondary — the skill ceiling is strategy (pattern recognition, approach selection, tradeoff judgment), and strategy is built in **review**, not in gates.

## What v4 got wrong (and v5 fixes)

1. **Overuse of AI.** v4 put an LLM in the core content loop — no API key/network, no new problems. v5's core loop is 100% offline and free. AI is an optional garnish (Phase 4), never load-bearing.
2. **Prescriptive judging kills discovery.** v3/v4 carried structural rules ("a sliding window requires a loop") and feedback that assumed *which* solution you wrote. If the fun is discovering your own approach, the judge must be a **black box**: it observes behavior (correct outputs) and physics (measured speed at scale) and nothing else. A weird, novel, correct, fast solution passes — and *should*.
3. **Effort on the input side instead of the output side.** The learning moment isn't the problem statement; it's the ten minutes after you solve it. v5 moves most of the system to post-solve output: measured performance, solve time vs personal best, and an **editorial** — multiple named approaches with real code and tradeoff notes, revealed only after you've earned them. VOD review, not a tutorial.

## 1. Design invariants

- **Black-box judge.** The only gates, ever: (a) tests pass, (b) execution fits a generous time budget at adversarial input sizes. No AST checks, no "did you use a HashMap," no required idioms. Your file just needs a `fun solve(...)` matching the signature — helpers, classes, extension functions, whatever style you want around it is your business.
- **Discovery first, editorial after.** Hints exist but only on demand (`:DojoHint`). Alternative approaches are hidden until the archetype is complete (`:DojoReview`, bang to force-spoil).
- **Offline, free, instant to start.** Problems are Lua data + Kotlin expressions. `brew install kotlin` is the only dependency. No accounts, no network, no key.
- **Timed like the dojo.** Every stage records solve time; personal bests persist. Same culture as `dojo`'s stars and PBs — speed pressure is how mechanics stay honest while strategy is the focus.

## 2. Variations without AI: answers by construction

The v4 plan generated variations with an LLM and verified them against reference solutions. Unnecessary. For algorithm problems you can generate unbounded test inputs whose answers are **known by construction**:

- *Two sum at N=500,000*: `nums[i] = 2i` (all distinct, one planted pair is the unique answer — provable, not assumed).
- *Longest unique substring at N=2,000,000*: cycle the alphabet; answer is exactly 26.
- *Container with most water at N=200,000*: all heights 1; answer is exactly N−1.

Seeded randomization of the same constructions (shuffle positions, vary the planted pair) yields infinite concrete variations with exact expected answers, zero AI, zero runtime reference-solution execution. Since tests are literal Kotlin expressions in the schema, a "generator" is just a `run { … }` block that builds the input inline. This is the variation engine: **constructive generators, compounded across archetypes × input shapes × scales.**

Complexity enforcement falls out for free: at these sizes, any O(N)/O(N log N) solution finishes in tens of milliseconds while O(N²) takes minutes. A generous wall-clock budget (~3s) separates them with no bytecode instrumentation, no curve fitting, no noise-sensitivity. (Scaling-ratio checks can be added later if a boundary case ever demands it.)

## 3. Core loop

```
:DojoLeetcodeStart <archetype>
   ▼
Stage constraint shown · real .kt file on disk (full LSP — it IS your neovim)
   ▼
You solve it YOUR way ──:DojoValidate──► compile + run (async, ~4s kotlinc)
   │                                        tests: this stage + ALL prior stages (regression)
   │                                        perf tests: constructed adversarial N, time-budgeted
   ▼
PASS → solve time vs PB recorded → :DojoNext escalates the constraint
   ▼
All stages complete → :DojoReview unlocks the editorial:
   every named approach, real Kotlin, complexity, tradeoffs,
   including approaches that would have FAILED a later stage and why
```

Stage escalation is purely behavioral: a new constraint is new tests and/or a perf bar — never "now use technique X." If your stage-1 solution already survives stage 2, that's not cheating, that's engineering.

## 4. Modules (implemented)

- **`judge.lua`** — writes submission + generated harness to a `.kts`, runs `kotlinc -script` via `vim.system` (async, 30s hard kill for infinite loops). Harness times each case with `System.nanoTime`, prints `DOJO_RESULT` / `DOJO_TIME` lines; Lua parses and applies per-test `budget_ms`. Measurement in Kotlin, policy in Lua.
- **`progression.lua`** — stage state machine. Flattens tests from stage 1..current for every validation (regression enforcement for free). Advancing requires a passing validate *of the current stage* — the gate is having actually solved it, not asking to move on.
- **`state.lua`** — `~/.local/state/dojo-leetcode/progress.json`: stage, attempts/passes, per-stage personal-best solve times.
- **`ui.lua`** — constraint pane + workspace `.kt` split; results with per-test pass/fail and timing; solve-time + PB display; editorial renderer (markdown buffer with Kotlin fences, treesitter does the rest).
- **`archetypes/*.lua`** — data only: scaffold, stages (constraint, tests, optional `budget_ms` + `slow_msg`), on-demand hints, and `approaches` (the editorial: name, complexity, tradeoff note, full code).

- **App shell** — this must feel like a full leetcode app, not commands feeding notifications:
  - `:Dojo` dashboard: problem list with progress/PBs, kotlinc status, workspace path, first-run walkthrough; `<CR>` to enter.
  - Persistent three-pane tab: problem (left) · your code (right) · results console (below). Panes are validity-checked and rebuilt if closed — output can never vanish into a dead buffer.
  - Results show *real output*: actual values (arrays pretty-printed), your own `println`s captured into a console section, per-test timing, compile+run wall time.
  - `:DojoTry <expr>` (`,y`): REPL-style — compile the buffer, evaluate any expression, see the value/prints/exception raw. No judgment.
  - Custom tests: `:DojoTestAdd` (`,t`) prompts call+expected, stored per-problem as hand-editable JSON (`:DojoTests`), runs with every validate.
  - Buffer-local keymaps in dojo panes (`,r` run · `,y` try · `,t` add test · `,h` hint · `,n` next · `,v` review · `,d` menu).
  - `quiet_lsp` (default on): kotlin-lsp diagnostics are muted in workspace buffers — a lone `.kt` with no gradle project produces noise the judge doesn't care about; completion/hover keep working. `:checkhealth dojo-leetcode` verifies kotlinc/LSP/workspace/archetypes.
  - Session adoption: reopen nvim on a workspace `.kt` and `:DojoValidate` just works — the session is rebuilt from the filename.

Commands: `:Dojo [problem]` `:DojoValidate` `:DojoNext` `:DojoHint` `:DojoReset` `:DojoReview[!]` `:DojoTry` `:DojoTestAdd` `:DojoTests`.

## 5. The strategy layer (roadmap)

Faker-level macro is *recognition* — reading a fight and knowing the play. Interview equivalent: read a novel problem statement and know the archetype, the approach, and the complexity target within a minute. Build order:

1. **Now — Phase 1 (done):** 3 archetypes, black-box judge, perf bars, editorials, PBs.
2. **Phase 2 — breadth:** grow to ~15–20 archetypes covering the FAANG canon (graph BFS/DFS, 1D/2D DP, heap, intervals, union-find, binary search on answer, backtracking, monotonic stack…). Each gets constructive generators + a real editorial. Content is the moat; the engine is done.
3. **Phase 3 — recognition drills (`:DojoRecall`):** flash a problem statement (a *variation*, so memorized titles don't help), you commit to an archetype + complexity target in ≤60s, then reveal. Scored like dojo arcade. This is the macro trainer — separate from, and eventually more important than, the solving reps.
4. **Phase 4 — optional AI garnish, never core:** post-solve commentary on *your specific code* (the one thing static editorials can't do) and novel prose for recall drills. Cached, offline-degradable, off by default.
5. **System design** rides on Phase 3's skeleton (prompt → committed answer → reveal → self-score against a rubric), not on the judge. Design it when Phase 3 exists.

## 6. Relationship to `dojo`

Unchanged: separate plugin (needs live LSP buffers), thin `dojo` course entry point later, shared state-dir conventions so `dojo stats` can eventually aggregate. Mechanics training (vim drills, Dvorak speed) stays in `dojo` where it already works; this plugin assumes those mechanics and trains judgment.
