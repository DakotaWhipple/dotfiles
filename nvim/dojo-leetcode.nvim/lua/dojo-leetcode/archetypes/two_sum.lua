return {
  id = "two_sum",
  title = "Two Sum",
  scaffold = "fun solve(nums: IntArray, target: Int): IntArray {\n\n}\n",

  stages = {
    {
      constraint = "Given an array of integers `nums` and an integer `target`, "
        .. "return the indices of the two numbers that add up to `target`. "
        .. "Exactly one valid answer exists.",
      hint = "Brute force is a nested loop, O(N^2). Instead, walk the array once "
        .. "and map each value you've seen to its index — then for each new "
        .. "number, check whether its complement is already in the map.",
      tests = {
        { call = "solve(intArrayOf(2,7,11,15), 9)", expected = "intArrayOf(0,1)" },
        { call = "solve(intArrayOf(3,2,4), 6)", expected = "intArrayOf(1,2)" },
        { call = "solve(intArrayOf(3,3), 6)", expected = "intArrayOf(0,1)" },
      },
    },
    {
      constraint = "Twist: `nums` may contain negative numbers, and there may be "
        .. "no valid pair at all — in that case return an empty IntArray, not null.",
      hint = "HashMap doesn't care whether keys are negative. For 'no solution', "
        .. "just let the loop finish and fall through to `return intArrayOf()`.",
      tests = {
        { call = "solve(intArrayOf(-3,4,3,90), 0)", expected = "intArrayOf(0,2)" },
        { call = "solve(intArrayOf(1,2,3), 100)", expected = "intArrayOf()" },
      },
    },
  },
}
