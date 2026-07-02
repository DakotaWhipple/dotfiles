fun solve(height: IntArray): Int {
    var left = 0
    var right = height.size - 1
    var best = 0
    while (left < right) {
        val area = (right - left) * minOf(height[left], height[right])
        best = maxOf(best, area)
        if (height[left] < height[right]) left++ else right--
    }
    return best
}
