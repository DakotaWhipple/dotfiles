# Dojo LeetCode Neovim Plugin Architecture (v4)

**Goal:** go from "what's a two sum?" to Anthropic-senior-engineer-level problem solving, in Kotlin, at Dvorak-neovim speed — with an engine that can later extend to system design without a rewrite.

v3 (previous draft) had the right instincts on progression/persistence but got ahead of itself on judge rigor (ASM bytecode instrumentation, a detekt daemon) before a single problem existed, and didn't resolve how "infinite variations" actually gets built. This version resolves those.

## 0. Decisions made without your sign-off — override any of these

I asked and got no response in time, so I proceeded with the recommended option on each. These are real preference calls, not settled facts — say the word and I'll flip any of them:

| Decision | Chosen | Alternatives you can still pick |
|---|---|---|
| Problem sourcing | Custom curated bank, no leetcode.nvim dependency | Hybrid seed from leetcode.nvim; full leetcode.nvim integration |
| Variation generation | LLM-generated at runtime, cached to disk | Fully hand-authored schemas; template/procedural (no LLM) |
| Judge rigor for v1 | Compile + execute + empirical timing only | Full ASM bytecode instrumentation + detekt daemon from day one |
| System design scope | Deferred — ship algorithms trainer first, generalize later | Design a unified engine for both content types now |

---

## 1. Relationship to the existing `dojo` trainer

`dojo` (bash, `~/dotfiles/dojo/`) drills muscle memory: shell tasks, vim edit drills checked via `nvim -l`, arcade mode, gym mode, TSV state in `~/.local/state/dojo/scores.tsv`. It's pure bash, zero dependencies, and it's already good at what it does.

This project is **not a dojo course**. It needs a real editor session (LSP, a live Kotlin buffer, multi-stage UI) that bash-driving-nvim-headlessly can't give you, so it's a proper Neovim plugin. Two seams tie them together instead of merging them:

- **Entry point**: `dojo` gets a thin course (`dojo/courses/NN-leetcode/course.sh`) whose only job is `nvim -c "DojoLeetcodeStart"` — so `dojo leetcode` is muscle memory, same as everything else you drill.
- **State convention**: mirrors dojo's layout — `~/.local/state/dojo-leetcode/{progress.json,variations/,scores.tsv}` — so `dojo stats` can eventually read both without special-casing.

Nothing more coupled than that. The plugin stands alone if `dojo` ever changes.

## 2. Why not ECS

ECS earns its cost when you have many live entities with heterogeneous, orthogonal components, queried every frame under performance pressure — that's a game loop problem. You have exactly one active problem instance at a time, no per-frame query pattern, and the actual axes of variation (a constraint, a test set, a feedback string, a difficulty) are already a natural **ordered pipeline**, not a component soup that needs runtime composition/querying. Reaching for ECS here would add a layer of indirection (component registries, systems, queries) that buys nothing — a stage list + a small content model does the same job more legibly. Skip it.

## 3. Core Modules

### 3.1 Content Model — Archetype → Constraint Dimensions → Variation

This is the piece v3 was missing. Three layers, cleanly separated so "infinite variations" doesn't mean "infinite hand-authoring":

- **Archetype**: an evergreen pattern (`sliding_window`, `two_pointer`, `graph_bfs`, `dp_1d`, `union_find`, …). Hand-authored, small in number (~15–20 covers most of the FAANG canon). Each archetype ships with:
  - a canonical base statement and scaffold
  - **one or more trusted reference solutions** (hand-written, per difficulty tier) — this is load-bearing, see 3.3
  - a list of applicable **constraint dimensions**: `scale` (adversarial N), `encoding` (unicode/BMP traps), `memory` (O(1) space), `streaming` (can't hold the whole input), `concurrency` (thread-safety), `real_world` (messy/malformed input) — each dimension is a short spec, not full prose
- **Variation**: a concrete instantiated problem — specific constraint text, specific generated test cases, specific feedback strings — for one archetype × one combination of dimensions. Variations are *generated*, not hand-written, and cached.

This is what makes variations compound: a new archetype × existing dimension automatically yields new variations without new authoring, and a new dimension applies retroactively to every existing archetype.

### 3.2 Variation Generator (the actual answer to "infinite")

At `:DojoNext` (or during idle pre-fetch), the plugin calls Claude with: the archetype spec, the constraint dimension(s) selected for this stage, the variations already served to this user (avoid repeats), and a skill signal pulled from `progress.json` (what this user has struggled with). It returns constraint prose, a test generator spec, and Senior-Engineer-style feedback strings for the failure modes you'd expect at this stage.

**Never trust the LLM's stated expected output.** The generator returns *inputs* and a natural-language constraint; the *expected* value for every test case is derived by executing the archetype's trusted reference solution (3.1) against that input, not by asking the LLM what the answer is. This is the difference between "infinite variations" and "infinite plausible-looking wrong answers." A generated variation that the reference solution can't run cleanly (parse error, ambiguous input) is rejected and regenerated, never shown to the user.

Generated variations are cached at `~/.local/state/dojo-leetcode/variations/<archetype>/<dimension-hash>.json`, so repeats are free and the trainer works offline once you've built up a local library. No network, no plugin — same as any cache-miss-on-first-use system.

### 3.3 Progression Engine (State Machine) — unchanged from v3, it was right

- Manages a problem as a queue of `Stages`; passing Stage N injects Stage N+1's constraint into the buffer and re-evaluates.
- **Regression enforcement**: advancing to Stage N re-runs all tests from Stages 1..N-1 (plus edge cases) — solutions must stay backward-compatible.
- **Persistence**: `~/.local/state/dojo-leetcode/progress.json`, tracks per-archetype mastery signal (used by 3.2 to bias future variation selection toward weak spots).

### 3.4 Validation Pipeline (the "Interviewer") — v1 scope, deliberately simplified

v3 wanted mathematically exact complexity proof via bytecode instrumentation before a single problem was buildable. That's backwards — ship the trainer, add rigor once you're actually using it.

1. **Compile**: persistent Kotlin daemon (`kotlinc` in daemon mode, or embedded Kotlin scripting host) — kills the 2–8s cold start without building custom tooling.
2. **Execute + regress**: each submission runs in a fresh `URLClassLoader`, discarded after, for deterministic stateless runs — this part of v3 was correct and worth keeping as-is.
3. **Complexity — empirical, not instrumented**: time N, 2N, 4N after discarding JIT warmup runs, classify by log-log slope. Slopes that land in an ambiguous band (e.g. between "clearly linear" and "clearly quadratic") are reported as *ambiguous, re-run at larger N* rather than false-confidently classified. Good enough to catch the O(N)-vs-O(N²) mistakes that actually show up at this stage; add ASM instrumentation later only if empirical timing proves too noisy in practice.
4. **Structural (Tree-sitter)**: soft signal only (e.g. "no loop found, are you sure?") — never a hard gate. v3 already scoped this correctly.
5. **Style feedback**: no detekt daemon in v1. The same LLM call that authors feedback strings for the failure modes (3.2) can comment on style directly against the submitted code — you already have the model in the loop for teaching, no reason to stand up a second JVM daemon before you need it.

### 3.5 Feedback UI — unchanged from v3

`extmarks` + Diagnostics API, Senior-Engineer-voice feedback strings sourced from the Variation (3.2), not hard-coded per problem.

### 3.6 Efficiency telemetry (ties back to why this project started)

The original motivation was Dvorak/neovim mastery, not just LeetCode correctness — don't lose that. Alongside pass/fail, the plugin tracks per-submission: keystroke count, arrow-key usage, and non-home-row navigation (reusing the counting approach `dojo`'s vim drills already use), surfaced as a secondary "how you solved it" score next to the correctness score. This is coaching, never a gate — a correct O(N) solution typed inefficiently still passes, it just gets a note.

---

## 4. Data Flow

```
Archetype (hand-authored, ~15-20)
   │  + constraint dimension(s) picked by Progression Engine
   ▼
Variation Generator ──(cache hit?)──► cached Variation JSON
   │ (cache miss)
   ▼
Claude API: constraint prose + test input specs + feedback strings
   ▼
Reference solution executes each generated input → derives EXPECTED output
   ▼
Reject & regenerate if reference solution errors, else cache Variation
   ▼
Progression Engine renders Stage N (buffer + constraint + tests)
   ▼
User writes Kotlin ──:DojoValidate──► Compile → Execute/Regress → Complexity → Feedback
   ▼
Pass → progress.json updated (mastery signal) → next Stage/dimension chosen
```

---

## 5. Problem Schema (Archetype, not per-variation)

```lua
-- lua/dojo-leetcode/archetypes/sliding_window.lua
return {
  id = "sliding_window",
  title = "Sliding Window",
  language = "kotlin",
  scaffold = "fun solve(s: String): Int {\n\n}",

  -- Hand-written, trusted. Used to derive expected() for every
  -- generated variation — never trust the LLM's stated answer.
  reference_solutions = {
    baseline = "kotlin/reference/sliding_window_baseline.kt",
    optimal  = "kotlin/reference/sliding_window_optimal.kt",
  },

  applicable_dimensions = { "scale", "encoding", "memory", "real_world" },

  structural_rules = {
    require_loop = {
      query = "[(for_statement) (while_statement) (call_expression)] @loop",
      msg = "A sliding window requires iterating over the sequence. Start with a loop.",
    },
  },
}
```

A generated Variation (cached JSON, not hand-written) looks like the old v3 `stages[n]` shape — constraint text, tests (`expected` always reference-derived), and feedback strings — but is produced by 3.2, not typed by a human.

---

## 6. Plugin API & Commands

```lua
{
  "koda/dojo-leetcode.nvim",
  opts = {
    workspace_dir = "~/.local/state/dojo-leetcode",
    anthropic_api_key_cmd = "op read op://...", -- pull from your secrets manager, not a literal key
  }
}
```

- `:DojoLeetcodeStart [archetype_id]` — opens the split, loads/generates Stage 1.
- `:DojoValidate` — runs the pipeline (Structural → Compile → Execute/Regress → Complexity → Feedback).
- `:DojoNext` — advances stage; may trigger a variation-generator cache miss.
- `:DojoReset` — wipes progress for the current archetype.
- `:DojoHint` — reveals the current stage's hint from the cached Variation.

---

## 7. Roadmap

1. **Phase 1 — prove the UX, no LLM yet.** Progression engine, validation pipeline (3.4), feedback UI, 5 archetypes with hand-written reference solutions and 2–3 *hand-authored* stage variations each (two sum, sliding window, two pointer, graph BFS, 1D DP). Confirms the core loop feels good before building the generator.
2. **Phase 2 — wire the Variation Generator.** LLM calls, caching, reference-solution-derived expected values, rejection/regeneration on reference-solution failure. This is where "infinite variations" actually turns on.
3. **Phase 3 — generalize.** Once real usage has exercised the archetype/dimension split, extract the content-type-agnostic core (progression, caching, feedback UI) from the Kotlin-specific judge, and add a system-design archetype type. System design needs its own judge design (no compiler to lean on — likely an LLM-graded rubric against a checklist schema) — don't design that now, design it once Phase 1–2 have taught you what actually generalizes.
