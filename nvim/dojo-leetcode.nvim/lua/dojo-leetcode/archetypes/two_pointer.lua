return {
  id = "two_pointer",
  title = "Container With Most Water",
  scaffold = "fun solve(height: IntArray): Int {\n\n}\n",

  stages = {
    {
      constraint = "Given an array `height` where `height[i]` is the height of a "
        .. "vertical line at position i, find two lines that together with the "
        .. "x-axis form a container holding the most water. Return the max area.",
      hint = "Start with the widest possible container. To ever do better than "
        .. "it, something about it has to change — which of its two walls is "
        .. "even worth replacing?",
      tests = {
        { call = "solve(intArrayOf(1,8,6,2,5,4,8,3,7))", expected = "49" },
        { call = "solve(intArrayOf(1,1))", expected = "1" },
      },
    },
    {
      constraint = "Twist: all heights may be equal, or the array may have only "
        .. "two elements. No special-casing — if your invariant is right, "
        .. "these already work.",
      hint = "If you added an `if` for these, ask what your main loop was "
        .. "missing that made the `if` feel necessary.",
      tests = {
        { call = "solve(intArrayOf(4,4,4,4))", expected = "12", diag = "edge case: all heights equal" },
        { call = "solve(intArrayOf(0,2))", expected = "0", diag = "edge case: two elements, one zero-height" },
      },
    },
    {
      constraint = "Scale: 200,000 lines, 3 second budget. Checking every pair "
        .. "is 20 billion areas — the geometry has to do the pruning for you.",
      hint = "The area is capped by the shorter wall. Moving the TALLER pointer "
        .. "inward can only shrink width without raising the cap — so that "
        .. "move is never worth exploring. That one sentence deletes "
        .. "O(N²) - O(N) of the search space.",
      tests = {
        -- All heights 1: every pair's area is just its width, so the max is
        -- the full span, N-1. Answer by construction.
        {
          call = "run { solve(IntArray(200_000) { 1 }) }",
          expected = "199999",
          budget_ms = 3000,
          slow_msg = "Every pair is ~2e10 area computations. The shorter-wall argument reduces it to a single N-step walk.",
        },
      },
    },
  },

  approaches = {
    {
      name = "Two pointers from the ends (greedy + exchange argument)",
      complexity = "O(N) time · O(1) space",
      note = "The code is five lines; the interview is the PROOF. Exchange "
        .. "argument: any pair you 'skipped' by moving the shorter wall inward "
        .. "had area ≤ the pair you just measured (same short wall, less "
        .. "width), so nothing better was discarded. Interviewers probe this "
        .. "exact point — being able to say it cleanly IS the senior signal. "
        .. "Note ties (equal walls): moving either is safe, which is why "
        .. "stage 2's all-equal case needs no special handling.",
      code = [=[
fun solve(height: IntArray): Int {
    var left = 0; var right = height.size - 1; var best = 0
    while (left < right) {
        best = maxOf(best, (right - left) * minOf(height[left], height[right]))
        if (height[left] < height[right]) left++ else right--
    }
    return best
}]=],
    },
    {
      name = "Brute force every pair",
      complexity = "O(N²) time · O(1) space",
      note = "Passes stages 1–2, dies at stage 3 (~2e10 operations vs 3s). "
        .. "Worth writing once anyway: in an interview, stating 'brute force "
        .. "is every pair, O(N²), let's beat it' takes ten seconds and buys "
        .. "you a correct baseline to check the clever version against.",
      code = [=[
fun solve(height: IntArray): Int {
    var best = 0
    for (i in height.indices)
        for (j in i + 1 until height.size)
            best = maxOf(best, (j - i) * minOf(height[i], height[j]))
    return best
}]=],
    },
  },
}
