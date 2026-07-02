fun solve(nums: IntArray, target: Int): IntArray {
    val seen = HashMap<Int, Int>()
    for (i in nums.indices) {
        val need = target - nums[i]
        if (seen.containsKey(need)) return intArrayOf(seen[need]!!, i)
        seen[nums[i]] = i
    }
    return intArrayOf()
}
