return {
  id = "sliding_window",
  title = "Longest Substring Without Repeating Characters",
  scaffold = "fun solve(s: String): Int {\n\n}\n",

  stages = {
    {
      constraint = "Given a string `s`, return the length of the longest substring "
        .. "without repeating characters.",
      hint = "Every substring is defined by two edges. When the right edge hits "
        .. "a repeat, what's the laziest thing the left edge could do about it?",
      tests = {
        { call = [[solve("abcabcbb")]], expected = "3" },
        { call = [[solve("bbbbb")]], expected = "1" },
        { call = [[solve("")]], expected = "0", diag = "edge case: empty string" },
        { call = [[solve("pwwkew")]], expected = "3" },
      },
    },
    {
      constraint = "Twist: `s` may contain non-ASCII characters (still within the "
        .. "Basic Multilingual Plane, so one Kotlin Char == one visible character). "
        .. "Uniqueness must still be tracked correctly.",
      hint = "Does anything in your solution silently assume there are only "
        .. "128 possible characters?",
      tests = {
        { call = [[solve("aαβα")]], expected = "3", diag = "edge case: non-ASCII chars (fixed-size alphabet assumption?)" },
      },
    },
    {
      constraint = "Scale: 2,000,000 characters. 3 second budget. If you're "
        .. "rebuilding or rescanning the window contents on every step, "
        .. "this is where it shows.",
      hint = "Amortize: how many times can each character enter the window? "
        .. "Leave it? If either answer is 'more than once', there's your bill.",
      tests = {
        -- Cycling a 26-letter alphabet: the longest run of unique chars is
        -- exactly 26, by construction, at any length.
        {
          call = "run { val sb = StringBuilder(2_000_000); repeat(2_000_000) { sb.append('a' + (it % 26)) }; solve(sb.toString()) }",
          expected = "26",
          budget_ms = 3000,
          slow_msg = "Each char should enter and leave your window at most once. Materializing substrings or rescanning the window makes every step O(window).",
        },
      },
    },
  },

  approaches = {
    {
      name = "Two pointers + HashSet (shrink until valid)",
      complexity = "O(N) time · O(min(N, alphabet)) space",
      note = "The honest first sliding window. Looks like it might be O(N²) "
        .. "because of the inner while — it isn't: each character enters the "
        .. "set once and leaves at most once, so the total work is 2N. That "
        .. "amortized argument is a reusable interview weapon; say it out loud.",
      code = [=[
fun solve(s: String): Int {
    val window = HashSet<Char>()
    var left = 0; var best = 0
    for (right in s.indices) {
        while (s[right] in window) { window.remove(s[left]); left++ }
        window.add(s[right])
        best = maxOf(best, right - left + 1)
    }
    return best
}]=],
    },
    {
      name = "Last-seen index map (jump, don't crawl)",
      complexity = "O(N) time · O(min(N, alphabet)) space",
      note = "The refinement: instead of shrinking one char at a time, remember "
        .. "WHERE you last saw each char and teleport `left` past it. Same big-O "
        .. "as the HashSet version but fewer operations per step and no inner "
        .. "loop at all. The `>= left` guard is the classic off-by-one trap: a "
        .. "stale last-seen index BEHIND the window must be ignored.",
      code = [=[
fun solve(s: String): Int {
    val lastSeen = HashMap<Char, Int>()
    var left = 0; var best = 0
    for (right in s.indices) {
        val prev = lastSeen[s[right]]
        if (prev != null && prev >= left) left = prev + 1
        lastSeen[s[right]] = right
        best = maxOf(best, right - left + 1)
    }
    return best
}]=],
    },
    {
      name = "IntArray(128) micro-optimization",
      complexity = "O(N) time · O(1) space — but ASCII-only",
      note = "A real optimization you'll see in competitive code: replace the "
        .. "map with a fixed array indexed by char code. Fastest of the three — "
        .. "and it's exactly what stage 2 exists to break: 'α' has char code "
        .. "945 and indexes out of bounds (or silently collides if you mask). "
        .. "The meta-lesson: every representation shortcut is a hidden "
        .. "assumption about the input; name the assumption before you take "
        .. "the shortcut.",
      code = [=[
fun solve(s: String): Int {  // FAILS stage 2 on purpose
    val lastSeen = IntArray(128) { -1 }
    var left = 0; var best = 0
    for (right in s.indices) {
        val c = s[right].code            // 945 for 'α' → boom
        if (lastSeen[c] >= left) left = lastSeen[c] + 1
        lastSeen[c] = right
        best = maxOf(best, right - left + 1)
    }
    return best
}]=],
    },
  },
}
