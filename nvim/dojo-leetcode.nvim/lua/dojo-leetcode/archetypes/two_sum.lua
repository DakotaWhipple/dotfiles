return {
  id = "two_sum",
  title = "Two Sum",
  scaffold = "fun solve(nums: IntArray, target: Int): IntArray {\n\n}\n",

  stages = {
    {
      constraint = "Given an array of integers `nums` and an integer `target`, "
        .. "return the indices of the two numbers that add up to `target`. "
        .. "Exactly one valid answer exists.",
      hint = "How would you check, for each number, whether its partner has "
        .. "already walked past you — without walking back?",
      tests = {
        { call = "solve(intArrayOf(2,7,11,15), 9)", expected = "intArrayOf(0,1)" },
        { call = "solve(intArrayOf(3,2,4), 6)", expected = "intArrayOf(1,2)" },
        { call = "solve(intArrayOf(3,3), 6)", expected = "intArrayOf(0,1)" },
      },
    },
    {
      constraint = "Twist: `nums` may contain negative numbers, and there may be "
        .. "no valid pair at all — in that case return an empty IntArray, not null.",
      hint = "If your approach was value-based, does it care whether values are "
        .. "negative? And what naturally happens if the loop just... finishes?",
      tests = {
        { call = "solve(intArrayOf(-3,4,3,90), 0)", expected = "intArrayOf(0,2)", diag = "edge case: negative numbers" },
        { call = "solve(intArrayOf(1,2,3), 100)", expected = "intArrayOf()", diag = "edge case: no valid pair (return empty, not null)" },
      },
    },
    {
      constraint = "Scale: `nums` now has 500,000 elements and your answer is "
        .. "hiding at the far end. Same rules — but you have a 3 second budget.",
      hint = "Count the work. If for each element you re-scan the rest of the "
        .. "array, that's ~125 billion comparisons here. What single-pass "
        .. "structure answers 'have I seen target - x?' in O(1)?",
      tests = {
        -- nums[i] = 2i: all distinct; i+j must equal 999997 with j<=499999,
        -- which forces the unique pair (499998, 499999). Answer by construction.
        {
          call = "run { val nums = IntArray(500_000) { it * 2 }; solve(nums, 1_999_994) }",
          expected = "intArrayOf(499998, 499999)",
          budget_ms = 3000,
          slow_msg = "A nested scan is ~1.25e11 comparisons on this input. One pass with a value→index map does it in ~50ms.",
        },
      },
    },
  },

  -- Revealed by :DojoReview after all stages pass. The point is contrast:
  -- several genuinely valid roads, and what each one trades away.
  approaches = {
    {
      name = "One-pass hash map",
      complexity = "O(N) time · O(N) space",
      note = "The canonical interview answer. The insight worth keeping: you "
        .. "don't need pairs, you need to ask 'has my complement already "
        .. "appeared?' — turning a pair search into N single lookups. Also "
        .. "handles the duplicate case (3,3) for free, because you check "
        .. "before inserting.",
      code = [=[
fun solve(nums: IntArray, target: Int): IntArray {
    val seen = HashMap<Int, Int>()
    for (i in nums.indices) {
        seen[target - nums[i]]?.let { return intArrayOf(it, i) }
        seen[nums[i]] = i
    }
    return intArrayOf()
}]=],
    },
    {
      name = "Sort + two pointers",
      complexity = "O(N log N) time · O(N) space (to keep original indices)",
      note = "Valid, and the better answer for the FOLLOW-UP interviewers love: "
        .. "'what if you need all pairs / the array is already sorted / memory "
        .. "for a map is expensive?'. The trap: sorting destroys the original "
        .. "indices, so you must sort (value, index) pairs — people lose the "
        .. "indices in interviews constantly. Would pass every stage here, "
        .. "including the perf bar.",
      code = [=[
fun solve(nums: IntArray, target: Int): IntArray {
    val idx = nums.indices.sortedBy { nums[it] }
    var lo = 0; var hi = nums.size - 1
    while (lo < hi) {
        val sum = nums[idx[lo]] + nums[idx[hi]]
        when {
            sum == target -> return intArrayOf(
                minOf(idx[lo], idx[hi]), maxOf(idx[lo], idx[hi]))
            sum < target -> lo++
            else -> hi--
        }
    }
    return intArrayOf()
}]=],
    },
    {
      name = "Brute force (where everyone starts)",
      complexity = "O(N²) time · O(1) space",
      note = "Correct, and passes stages 1–2. Stage 3 kills it: ~1.25e11 "
        .. "comparisons vs a 3s budget. The lesson isn't 'brute force bad' — "
        .. "it's that stating it first, then improving it out loud, is exactly "
        .. "how strong interviews flow. Know its shape so you can name it fast.",
      code = [=[
fun solve(nums: IntArray, target: Int): IntArray {
    for (i in nums.indices)
        for (j in i + 1 until nums.size)
            if (nums[i] + nums[j] == target) return intArrayOf(i, j)
    return intArrayOf()
}]=],
    },
  },
}
