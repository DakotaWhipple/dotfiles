# Dojo LeetCode Neovim Plugin Architecture (v5)

**Goal:** "what's a two sum?" → Anthropic-senior-level interviewing, trained inside the best neovim setup possible. Doublelift mechanics, Faker macro: mechanics matter but are secondary — the skill ceiling is strategy (pattern recognition, approach selection, tradeoff judgment), and strategy is built in **review**, not in gates.

## What v4 got wrong (and v5 fixes)

META: Documentation ages quickly. v4 vs v5 will make that even worse. We should strive to architect structure that doesn't age.

1. **Overuse of AI.** v4 put an LLM in the core content loop — no API key/network, no new problems. v5's core loop is 100% offline and free. AI is an optional garnish (Phase 4), never load-bearing.
2. **Prescriptive judging kills discovery.** v3/v4 carried structural rules ("a sliding window requires a loop") and feedback that assumed *which* solution you wrote. If the fun is discovering your own approach, the judge must be a **black box**: it observes behavior (correct outputs) and physics (measured speed at scale) and nothing else. A weird, novel, correct, fast solution passes — and *should*.
META: This should not be an axis. Non-negotiable should be correct outputs. The "what makes this tool special" should be the architecture of the information feedback to push the user towards more input, process, and output optimal. VERY IMPORTANT Teaching the user through information hierarchy aware static analysis and runtime analysis. Leetcode has a debugger behind a paywall. Where we want our tool to feel like programming a normal kotlin project. Especially if we aim to be able to teach better system design through high abstraction of kotlin implementations (design twitter like scenarios). Leetcode also teaches how to plan out a solution (start with greedy for example) after the problem has already been attempted. We want our tool to not say "start with the spec" but use clever tooling (that works for real world projects) that would cause the user to move towards a thread that makes incremental steps towards the correct solution. For example, how a debbugger can test abstract invariants and could even have a tool to track state across breakpoints that could have an abstract mapping to the meaning that we've said is incremental steps towards success (like a number incrementing, then code changes, then that number increments with a filter or combos into a decision ). etc etc
3. **Effort on the input side instead of the output side.** The learning moment isn't the problem statement; it's the ten minutes after you solve it. v5 moves most of the system to post-solve output: measured performance, solve time vs personal best, and an **editorial** — multiple named approaches with real code and tradeoff notes, revealed only after you've earned them. VOD review, not a tutorial.
META: I think the learning moment is when the info hierarchy of the UX is able to be more abstract. More can be done with less effort. In many scenarios it makes sense to go back and look at what decision could have been better, I agree with that. But we're not primarily optimizing for reflective learning. We want real time accessible info that incrementally pushes us towards the solution and incrementally pushes us towards more efficient processes to reach better solutions faster and more efficiently.

## 1. Design invariants

- **Black-box judge.** The only gates, ever: (a) tests pass, (b) execution fits a generous time budget at adversarial input sizes. No AST checks, no "did you use a HashMap," no required idioms. Your file just needs a `fun solve(...)` matching the signature — helpers, classes, extension functions, whatever style you want around it is your business.
META: Black-box judge sounds terrible. I hate black boxes. This comment misinterpreted the request. I like the idea of fully utilizing our core tools and treesitter is a core tool. We just want flexibility in the implementation. I think we need to scope out how we can utilize treesitter before the implementation architecture
- **Discovery first, editorial after.** Hints exist but only on demand (`:DojoHint`). Alternative approaches are hidden until the archetype is complete (`:DojoReview`, bang to force-spoil).
- **Offline, free, instant to start.** Problems are Lua data + Kotlin expressions. `brew install kotlin` is the only dependency. No accounts, no network, no key.
META: If AI is critical for this to actually be functional, then that's ok and we should move towards that. We just want it information should be presented in a way that's clever UX. For example, popups that direct a users eyes away from where they're wanting to focus are terrible and not good UX. Top right notification popups say "this is global space anything can be here" the information there should be limited and if we require a notification it should be for a good reason. But also diagnostics being about linting when I'm focused on if my syntax is valid or if my syntax is optimal or if I'm headed towards too many state variables. It should have a good info hierarchy and emphasize principles of good design the princples that would be more important (this is positional info so should be positional, or this relates to the problem so should show where the problem space is) (Visual Hierarchy, Contrast / Color Contrast, Whitespace / White/Negative Spacing, Alignment, Proximity, Focal Point, Gestalt Principles, Size and Scale, Emphasis, Reading Patterns, Keyboard-First Navigation, Information Density & Minimization of Cognitive Load, Predictability & Ecosystem Consistency, State Visibility & Context Awareness, and Non-Blocking Performance). Also, an agent chat is good but having to type everything to the agent and it's not seamless with the diagnostics, structure/file/AST/etc tree views, leader menu, neovim/kitty status bar/tab bar, LSP/treesitter coloring, go-to and other lsp capabilities, definitions, clever mapping UX tricks to change top of info hierarchy in a window/dialog/etc or dive deeper into the hierarchy tree, etc etc. <https://m3.material.io/foundations> has a great grouping of product separations (reusability (tokens), content, layouts, customization, interaction, components). Tho, we're not really doing a design system. Tho, idk maybe we should.
- **Timed like the dojo.** Every stage records solve time; personal bests persist. Same culture as `dojo`'s stars and PBs — speed pressure is how mechanics stay honest while strategy is the focus.
META: Meh, any other cheaper LLM can add a timing aspect. Only you can do something like telemetry + relevant reports for all kotlin projects from the ground up without sacrificing the real-time UX axis.

## 2. Variations without AI: answers by construction

META: Changing the performance requirement should be a given. If we can't have good variations without AI, we should defer this. Just good to have an API to plug into.

The v4 plan generated variations with an LLM and verified them against reference solutions. Unnecessary. For algorithm problems you can generate unbounded test inputs whose answers are **known by construction**:

- *Two sum at N=500,000*: `nums[i] = 2i` (all distinct, one planted pair is the unique answer — provable, not assumed).
- *Longest unique substring at N=2,000,000*: cycle the alphabet; answer is exactly 26.
- *Container with most water at N=200,000*: all heights 1; answer is exactly N−1.

Seeded randomization of the same constructions (shuffle positions, vary the planted pair) yields infinite concrete variations with exact expected answers, zero AI, zero runtime reference-solution execution. Since tests are literal Kotlin expressions in the schema, a "generator" is just a `run { … }` block that builds the input inline. This is the variation engine: **constructive generators, compounded across archetypes × input shapes × scales.**

Complexity enforcement falls out for free: at these sizes, any O(N)/O(N log N) solution finishes in tens of milliseconds while O(N²) takes minutes. A generous wall-clock budget (~3s) separates them with no bytecode instrumentation, no curve fitting, no noise-sensitivity. (Scaling-ratio checks can be added later if a boundary case ever demands it.)

## 3. Core loop

META: DojoLeetcodeStart is such a weird entry point and the start of the loop feels just as bad as the rest. Core loops are good to surface, but they should be capability/architecture contexted with simple user story feel to it.

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

META: This section would be easier to read if it was more psuedo-code api feeling.

- **`judge.lua`** — writes submission + generated harness to a `.kts`, runs `kotlinc -script` via `vim.system` (async, 30s hard kill for infinite loops). Harness times each case with `System.nanoTime`, prints `DOJO_RESULT` / `DOJO_TIME` lines; Lua parses and applies per-test `budget_ms`. Measurement in Kotlin, policy in Lua.
META: this section says judge but reads a lot about time? Weird..
- **`progression.lua`** — stage state machine. Flattens tests from stage 1..current for every validation (regression enforcement for free). Advancing requires a passing validate *of the current stage* — the gate is having actually solved it, not asking to move on.
META:
- **`state.lua`** — `~/.local/state/dojo-leetcode/progress.json`: stage, attempts/passes, per-stage personal-best solve times.
- **`ui.lua`** — constraint pane + workspace `.kt` split; results with per-test pass/fail and timing; solve-time + PB display; editorial renderer (markdown buffer with Kotlin fences, treesitter does the rest).
- **`archetypes/*.lua`** — data only: scaffold, stages (constraint, tests, optional `budget_ms` + `slow_msg`, optional `diag` edge-case label), on-demand hints, and `approaches` (the editorial: name, complexity, tradeoff note, full code). `demo` is the feature tour: a pre-planted off-by-one, a ktlint bait line, and constraint text that walks through every instrument.
- **`diagnostics.lua`** — judge verdicts as native nvim diagnostics on the code buffer. kotlinc errors/warnings are mapped back to their real buffer lines (user source occupies lines 1..N of the submitted script); behavioral failures are classified — off-by-one (numeric actual = expected ± 1), archetype-labeled edge cases (`diag`), exception fingerprints (IndexOutOfBounds → loop-bound hint), SLOW budget misses as INFO — and anchored to `fun solve`. Cleared on a green run.

- **App shell** — this must feel like a full leetcode app, not commands feeding notifications:
  - `:Dojo` dashboard: problem list with progress/PBs, kotlinc status, workspace path, first-run walkthrough; `<CR>` to enter.
  - Persistent three-pane tab: problem (left) · your code (right) · results console (below). Panes are validity-checked and rebuilt if closed — output can never vanish into a dead buffer.
  - Results show *real output*: actual values (arrays pretty-printed), your own `println`s captured into a console section, per-test timing, compile+run wall time.
  - `:DojoTry <expr>` (`<leader>oy`): REPL-style — compile the buffer, evaluate any expression, see the value/prints/exception raw. No judgment.
  - Custom tests: `:DojoTestAdd` (`<leader>ot`) prompts call+expected, stored per-problem as hand-editable JSON (`:DojoTests`), runs with every validate.
  - `:DojoCases` (`<leader>oc`): the full untruncated test table — every call, expected value, budget, and custom case the next run will judge.
  - Buffer-local keymaps in dojo panes under `<leader>o` (dOjo; shows as a which-key "dojo" group): `r` run · `c` cases · `y` try · `t` add test · `h` hint · `n` next · `v` review · `d` menu. The old `,` prefix shadowed real vim/LazyVim keys.
  - Diagnostic layers, all native `vim.diagnostic` in the code buffer: kotlin-lsp does completion/hover only (the pre-alpha JetBrains server returns zero diagnostics for projectless files — verified empirically: hover resolves stdlib, `textDocument/diagnostic` pulls come back empty); ktlint lints on save via nvim-lint (LazyVim kotlin extra); the judge supplies compiler errors/warnings on real lines plus leetcode-level verdicts. `quiet_lsp` (now default **off** — it was hiding every layer, including ktlint) mutes them all if wanted. `:checkhealth dojo-leetcode` verifies kotlinc/LSP-attach/workspace/archetypes.
  - Session adoption: reopen nvim on a workspace `.kt` and `:DojoValidate` just works — the session is rebuilt from the filename.

Commands: `:Dojo [problem]` `:DojoValidate` `:DojoCases` `:DojoNext` `:DojoHint` `:DojoReset` `:DojoReview[!]` `:DojoTry` `:DojoTestAdd` `:DojoTests`. No entry point auto-opens a problem — `:Dojo` and no-arg `:DojoLeetcodeStart` land on the dashboard, always.

## 5. The strategy layer (roadmap)

Faker-level macro is *recognition* — reading a fight and knowing the play. Interview equivalent: read a novel problem statement and know the archetype, the approach, and the complexity target within a minute. Build order:

1. **Now — Phase 1 (done):** 3 archetypes, black-box judge, perf bars, editorials, PBs.
2. **Phase 2 — breadth:** grow to ~15–20 archetypes covering the FAANG canon (graph BFS/DFS, 1D/2D DP, heap, intervals, union-find, binary search on answer, backtracking, monotonic stack…). Each gets constructive generators + a real editorial. Content is the moat; the engine is done.
3. **Phase 3 — recognition drills (`:DojoRecall`):** flash a problem statement (a *variation*, so memorized titles don't help), you commit to an archetype + complexity target in ≤60s, then reveal. Scored like dojo arcade. This is the macro trainer — separate from, and eventually more important than, the solving reps.
4. **Phase 4 — optional AI garnish, never core:** post-solve commentary on *your specific code* (the one thing static editorials can't do) and novel prose for recall drills. Cached, offline-degradable, off by default.
5. **System design** rides on Phase 3's skeleton (prompt → committed answer → reveal → self-score against a rubric), not on the judge. Design it when Phase 3 exists.

## 6. Relationship to `dojo`

Unchanged: separate plugin (needs live LSP buffers), thin `dojo` course entry point later, shared state-dir conventions so `dojo stats` can eventually aggregate. Mechanics training (vim drills, Dvorak speed) stays in `dojo` where it already works; this plugin assumes those mechanics and trains judgment.
