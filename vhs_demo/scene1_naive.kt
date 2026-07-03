fun lengthOfLongestSubstring(s: String): Int {
    var left = 0
    var maxLength = 0
    val map = mutableMapOf<Char, Int>()
    
    for (right in s.indices) {
        val char = s[right]
        map[char] = map.getOrDefault(char, 0) + 1
        
        while (map.getOrDefault(char, 0) > 1) {
            val leftChar = s[left]
            map[leftChar] = map[leftChar]!! - 1
            left++
        }
        
        maxLength = maxOf(maxLength, right - left + 1)
    }
    
    return maxLength
}
