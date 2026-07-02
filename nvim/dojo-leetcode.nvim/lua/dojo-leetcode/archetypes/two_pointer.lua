return {
  id = "two_pointer",
  title = "Container With Most Water",
  scaffold = "fun solve(height: IntArray): Int {\n\n}\n",

  stages = {
    {
      constraint = "Given an array `height` where `height[i]` is the height of a "
        .. "vertical line at position i, find two lines that together with the "
        .. "x-axis form a container holding the most water. Return the max area.",
      hint = "Brute force checks every pair, O(N^2). Start two pointers at both "
        .. "ends instead: the area is capped by the SHORTER line, so moving the "
        .. "taller pointer inward can never increase it — always move the "
        .. "shorter one. That's the whole proof of correctness for O(N).",
      tests = {
        { call = "solve(intArrayOf(1,8,6,2,5,4,8,3,7))", expected = "49" },
        { call = "solve(intArrayOf(1,1))", expected = "1" },
      },
    },
    {
      constraint = "Twist: all heights may be equal, or the array may have only "
        .. "two elements. Don't special-case these — your pointer invariant "
        .. "should already handle them.",
      hint = "If your loop condition is `left < right` and you update the max "
        .. "before moving a pointer, equal-height arrays and 2-element arrays "
        .. "fall out for free — if they don't, you special-cased something "
        .. "that shouldn't need it.",
      tests = {
        { call = "solve(intArrayOf(4,4,4,4))", expected = "12" },
        { call = "solve(intArrayOf(0,2))", expected = "0" },
      },
    },
  },
}
