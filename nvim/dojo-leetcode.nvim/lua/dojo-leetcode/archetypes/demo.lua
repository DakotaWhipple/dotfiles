-- The feature tour. Not a real interview problem — a sandbox where every
-- dojo feature can be triggered on purpose, with nothing at stake. The
-- scaffold ships with a planted off-by-one so the first run FAILS and the
-- leetcode-level diagnostics show themselves immediately.
local config = require("dojo-leetcode.config")
local k = config.key

return {
  id = "demo",
  title = "Demo — feature tour (nothing at stake)",

  -- Pre-filled buggy solution: `until size - 1` skips the last element.
  -- Counting problems make off-by-one literal: actual = expected - 1,
  -- which is exactly what the off-by-one sniffer looks for. The double
  -- space before the comment is bait for ktlint (no-multi-spaces).
  scaffold = table.concat({
    "// dojo demo — this code is intentionally almost-right.",
    "// run the tests (" .. k("r") .. ") and watch the diagnostics land on this buffer.",
    "fun solve(nums: IntArray): Int {",
    "    var count = 0",
    "    for (i in 0 until nums.size - 1) {  // <- the planted bug",
    "        if (nums[i] % 2 == 0) count++",
    "    }",
    "    return count",
    "}",
    "",
  }, "\n"),

  stages = {
    {
      constraint = "Count the even numbers in `nums`.\n"
        .. "\n"
        .. "This stage is a tour, not a test. In order:\n"
        .. "  1. " .. k("c") .. " — see the full test cases (calls + expected)\n"
        .. "  2. " .. k("r") .. " — run. Two tests fail and the judge plants\n"
        .. "     off-by-one diagnostics on solve() — see the gutter, <leader>cd\n"
        .. "  3. fix the loop bound, " .. k("r") .. " again — diagnostics clear on a pass\n"
        .. "  4. " .. k("y") .. " — try any expression, e.g. solve(intArrayOf(1,2,3))\n"
        .. "  5. " .. k("t") .. " — add your own test; it runs on every future " .. k("r") .. "\n"
        .. "\n"
        .. "The other diagnostic levels, all visible in this one buffer:\n"
        .. "  linter — :w and ktlint flags the sloppy double-space on the\n"
        .. "           loop line (needs a second)\n"
        .. "  compiler — delete a closing brace, " .. k("r") .. ": kotlinc's error lands\n"
        .. "             on the real line, even mid-edit\n"
        .. "  lsp — K over IntArray: docs popup means kotlin-lsp is alive\n"
        .. "        (it does hover/completion here; its own diagnostics stay\n"
        .. "        empty outside a real project — that's the server, not you)",
      hint = "The planted bug: `0 until nums.size - 1` stops one short. "
        .. "`until` is already exclusive.",
      tests = {
        { call = "solve(intArrayOf(2, 4, 6))", expected = "3" },
        { call = "solve(intArrayOf(1, 3, 5))", expected = "0" },
        { call = "solve(intArrayOf(7, 8))", expected = "1" },
      },
    },
    {
      constraint = "Edge-case level. Same problem, hostile inputs: the empty\n"
        .. "array and negative evens (−4 is even; Kotlin's % keeps the sign,\n"
        .. "but -4 % 2 is still 0 — what about -3 % 2?).\n"
        .. "\n"
        .. "Fail one of these and the diagnostic names the edge case it\n"
        .. "belongs to, instead of a bare 'wrong answer'.",
      hint = "intArrayOf() has size 0 — does your loop survive that? "
        .. "And -3 % 2 == -1 in Kotlin, so `== 1` checks for odd would miss it.",
      tests = {
        { call = "solve(intArrayOf())", expected = "0", diag = "edge case: empty input" },
        { call = "solve(intArrayOf(-4, -3, -2))", expected = "2", diag = "edge case: negative numbers" },
      },
    },
    {
      constraint = "Performance level. One test now runs on 2,000,000 elements\n"
        .. "with a 500ms budget — any sane loop passes.\n"
        .. "\n"
        .. "Want to see the budget diagnostic without writing a bad algorithm?\n"
        .. "Add `Thread.sleep(600)` inside solve() and " .. k("r") .. ": the test turns\n"
        .. "SLOW (correct answer, over budget) and an INFO diagnostic appears.\n"
        .. "Remove it, pass, and " .. k("v") .. " unlocks the editorial.",
      hint = "Nothing to outsmart here — a single pass is ~10ms. This stage "
        .. "exists so you know what SLOW looks like before it matters.",
      tests = {
        {
          call = "run { val n = IntArray(2_000_000) { it }; solve(n) }",
          expected = "1000000",
          budget_ms = 500,
          slow_msg = "On real problems this means your approach is a complexity class too slow.",
        },
      },
    },
  },

  approaches = {
    {
      name = "The straight loop",
      complexity = "O(N) time · O(1) space",
      note = "There was never a trick. The demo's real content is the tooling: "
        .. "cases (" .. k("c") .. "), judge diagnostics in the gutter, try-expressions ("
        .. k("y") .. "), custom tests (" .. k("t") .. "), and the SLOW verdict. "
        .. "Every real problem uses the same instruments — now you know the dials.",
      code = [=[
fun solve(nums: IntArray): Int {
    var count = 0
    for (n in nums) if (n % 2 == 0) count++
    return count
}]=],
    },
    {
      name = "The idiomatic one-liner",
      complexity = "O(N) time · O(1) space",
      note = "Same machine, Kotlin's clothes. In interviews the loop is often "
        .. "the better opener — it leaves room to talk while you type.",
      code = [=[
fun solve(nums: IntArray): Int = nums.count { it % 2 == 0 }]=],
    },
  },
}
