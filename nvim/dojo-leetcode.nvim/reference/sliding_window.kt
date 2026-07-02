fun solve(s: String): Int {
    val lastSeen = HashMap<Char, Int>()
    var left = 0
    var best = 0
    for (right in s.indices) {
        val c = s[right]
        if (lastSeen.containsKey(c) && lastSeen[c]!! >= left) {
            left = lastSeen[c]!! + 1
        }
        lastSeen[c] = right
        best = maxOf(best, right - left + 1)
    }
    return best
}
