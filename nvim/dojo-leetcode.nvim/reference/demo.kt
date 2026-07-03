fun solve(nums: IntArray): Int {
    var count = 0
    for (n in nums) if (n % 2 == 0) count++
    return count
}
