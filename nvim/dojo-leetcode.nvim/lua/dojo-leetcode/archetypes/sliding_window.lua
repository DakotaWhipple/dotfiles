return {
  id = "sliding_window",
  title = "Longest Substring Without Repeating Characters",
  scaffold = "fun solve(s: String): Int {\n\n}\n",

  stages = {
    {
      constraint = "Given a string `s`, return the length of the longest substring "
        .. "without repeating characters.",
      hint = "Track the last-seen index of every character in a map. When the "
        .. "current character was already seen inside your current window, jump "
        .. "the window's left edge past that prior occurrence instead of "
        .. "incrementing it one step at a time — that's what makes it one pass.",
      tests = {
        { call = [[solve("abcabcbb")]], expected = "3" },
        { call = [[solve("bbbbb")]], expected = "1" },
        { call = [[solve("")]], expected = "0" },
        { call = [[solve("pwwkew")]], expected = "3" },
      },
    },
    {
      constraint = "Twist: `s` may contain non-ASCII characters (still within the "
        .. "Basic Multilingual Plane, so one Kotlin Char == one visible character). "
        .. "Your uniqueness tracking must still be correct.",
      hint = "Kotlin Strings are UTF-16 under the hood; iterating by Char already "
        .. "does the right thing here — the bug people hit is assuming ASCII and "
        .. "sizing a fixed IntArray(128) instead of using a Map<Char, Int>.",
      tests = {
        { call = [[solve("aαβα")]], expected = "3" },
      },
    },
  },
}
